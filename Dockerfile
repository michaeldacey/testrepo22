#########################################################################################
# The common environment setup
FROM ubuntu as base
MAINTAINER mike <michael.dacey@uwtsd.ac.uk>
ENV DEBIAN_FRONTEND    noninteractive
RUN apt-get update --fix-missing && \
apt-get install -y software-properties-common && \
apt-get install -y --no-install-recommends apt-utils && \
apt-get install -y curl wget
RUN apt-get install -y sudo
RUN apt-get install -y dos2unix
RUN echo "export SERVER_IP_ADDRESS='0.0.0.0'" >> /etc/profile
RUN apt-get clean

# Enable SSH
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update && \
apt-get install -y --no-install-recommends dialog && \
apt-get update && \
apt-get install -y --no-install-recommends openssh-server && \
echo "$SSH_PASSWD" | chpasswd 

# Copy the OpenSSH daemon configuration file
COPY sshd_config /etc/ssh/

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && \
apt-get install -y nodejs  
RUN npm install pm2@latest -g
RUN apt-get clean

# Create and change the working directory
WORKDIR /var/www/node

#########################################################################################
# Usage: docker image build --target local -t basicnodeapi .
# Create bind mount when you run the container.
# Usage: docker container run --name=nodeapi --volume "C:\<YourProjectPath>":/var/www/node -d -p 8081:80 basicnodeapi
FROM base as local
# Copy the Bash startup script that starts both SSH and the application
# Adding it to /usr/local/bin/ puts it in the PATH, alternatively copy it to .
# and then change to ENTRYPOINT ["./init.sh"]
COPY init.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/init.sh
RUN chmod u+x /usr/local/bin/init.sh

# If not running in Azure App Service use bind mount otherwise copy files into image
# THIS MOUNT IS ONLY FOR BUILDING, IN THIS EXAMPLE WE DO NOT NEED IT.
# RUN --mount=type=bind,target=/var/www/node,source=.
	
# Expose our webservice and SSH port number
EXPOSE 80 443

# Execute the application
ENTRYPOINT ["init.sh"]
#########################################################################################
# Usage: docker image build --target azureappservice_ci -t basicnodeapi .
FROM base as azureappservice_ci
# Copy the Bash startup script that starts both SSH and the application
# Adding it to /usr/local/bin/ puts it in the PATH
COPY init_azurewebapp.sh /usr/local/bin/
RUN dos2unix /usr/local/bin/init_azurewebapp.sh
RUN chmod u+x /usr/local/bin/init_azurewebapp.sh

# Copy reqd directories and files into image
COPY src src
COPY Dockerfile .
COPY package.json .
# For CI/CD the node_modules will be built by GitHub, so do not copy directory now

# Expose our webservices port number
# Port 2222 is an internal port accessible only by containers within the bridge network of a private virtual network.
EXPOSE 80 2222

# Execute the application
ENTRYPOINT ["init_azurewebapp.sh"]

FROM azureappservice_ci as azureappservice
# Usage: docker image build --target azureappservice -t basicnodeapi .
# Include the locally built node modules
COPY node_modules node_modules  
# Use the ENTRYPOINT above.
#########################################################################################
# Usage: docker image build --target localconnect -t basicnodeapi 
# For debug, uncomment the lines below and use the -it flags to run docker image
# Usage: docker container run --name=nodeapi --volume "C:\<YourProjectPath>":/var/www/node -it --rm -p 8081:80 basicnodeapi
FROM local as localconnect
RUN echo "Building local debug image"
ENTRYPOINT ["bash"]  


  