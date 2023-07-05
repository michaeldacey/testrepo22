const express = require('express');

const service = express();
const port = normalizePort(process.env.PORT || '80');

service.use(express.json());
service.use(express.urlencoded({extended:true}));

service.get('/', (req,res) => {
	res.send("Welcome!");
});

service.get('/hello/:name', (req,res) => {
	res.send(`Hello ${req.params.name}`);
});

service.listen(port, () => console.log(`Web service listening on port ${port}`));


// Normalize a port into a number, string, or false.
function normalizePort(val) {
  var port = parseInt(val, 10);

  if (isNaN(port)) {
    // named pipe
    return val;
  }

  if (port >= 0) {
    // port number
    return port;
  }

  return false;
}