#!/bin/bash
set -e

# Get env vars in the Dockerfile to show up in the SSH session
eval $(printenv | sed -n "s/^\([^=]\+\)=\(.*\)$/export \1=\2/p" | sed 's/"/\\\"/g' | sed '/=/s//="/' | sed 's/$/"/' >> /etc/profile)

# Start SSH
service ssh start

# Start the application
# For Azure (production) pm2 is the recommended approach to start node.js app
echo "Starting with PM2"
cd /var/www/node
pm2 start ./src/api.js --no-daemon -i 0
