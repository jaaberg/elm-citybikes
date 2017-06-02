const express = require('express');
const bodyParser = require('body-parser');
let http = require('http');
const axios = require('axios');

let app = express();

app.use(function (req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', process.env.SERVER || 'http://localhost:3000');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');
    res.setHeader('Access-Control-Allow-Credentials', true);
    next();
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

app.get('/available', function(req, res, next) {
  axios.get("https://oslobysykkel.no/api/v1/stations/availability", {
    headers: {'Client-Identifier': process.env.OSLO_BYSYKKEL_CLIENT_IDENTIFIER}
  })
  .then(function (response) {
    const trondheimsVeien = response.data.stations
      .filter(station => station.id == "257");
    res.status(200).send(trondheimsVeien[0]);
  })
  .catch(function (error) {
    console.log(error);
  });
});

http.createServer(app).listen(process.env.PORT || 3001, () => {
    console.log("Up and running");
});

process.on('SIGINT', function() {
    process.exit();
});
