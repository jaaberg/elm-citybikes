const express = require('express');
const bodyParser = require('body-parser');
let http = require('http');
const axios = require('axios');

let app = express();

app.use(express.static('./dist'));

app.get('/', function (req, res) {
  res.sendFile(path.join(__dirname, './dist', 'index.html'));
});

app.use(function (req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', process.env.SERVER || 'http://localhost:3000');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, PATCH, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'X-Requested-With,content-type');
    res.setHeader('Access-Control-Allow-Credentials', true);
    next();
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

function filterCycleStations(station) {
  return station.id == "257" || station.id == "262";
}

function mapCycleStations(station) {
  return {
    name: station.id == '257' ? "Trondheimsveien" : "Sofienberg",
    bikes: station.availability.bikes,
    locks: station.availability.locks
  }
}

function filterDepartures(departure) {
  return (departure.MonitoredVehicleJourney.LineRef == "31" || departure.MonitoredVehicleJourney.LineRef == "17")
      && departure.MonitoredVehicleJourney.DirectionRef == "2";
}

function mapDepartures(departure) {
  return {
    lineNumber : departure.MonitoredVehicleJourney.LineRef,
    destinationName : departure.MonitoredVehicleJourney.DestinationName,
    expectedDepartureTime : new Date(departure.MonitoredVehicleJourney.MonitoredCall.ExpectedDepartureTime).getTime()
  }
}

function fetchCityBikeCycles() {
  return axios.get("https://oslobysykkel.no/api/v1/stations/availability", {
    headers: {'Client-Identifier': process.env.OSLO_BYSYKKEL_CLIENT_IDENTIFIER}
  });
}

function fetchBuses() {
  return   axios.get("http://reisapi.ruter.no/StopVisit/GetDepartures/3010533");
}

app.get('/publictransportation', function(req, res, next) {
  axios.all([fetchCityBikeCycles(), fetchBuses()])
  .then(axios.spread(function (cycleResponse, departuresSofienbergResponse) {
    const bikes = cycleResponse.data.stations
      .filter(filterCycleStations)
      .map(mapCycleStations);
    const departuresSofienberg = departuresSofienbergResponse.data
      .filter(filterDepartures)
      .map(mapDepartures)
      .slice(0, 5);
    const busStations = [{
      name: "Sofienberg",
      departures: departuresSofienberg
    }];

    res.status(200).send({
      cityBikeStations: bikes,
      busStations: busStations
    })
  }));

});

http.createServer(app).listen(process.env.PORT || 3001, () => {
    console.log("Up and running");
});

process.on('SIGINT', function() {
    process.exit();
});
