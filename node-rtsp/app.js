var express = require('express');
var router  = express.Router();
var app     = express();
var request = require('request');
var fs      = require('fs')
var stream  = require('node-rtsp-stream');
var moment  = require('moment-timezone');
var wsock   = require('ws');
var wss     = new wsock.Server({port: 8007});
var port    = process.env.PORT || 3000;

app.set('views', __dirname + '/views');
app.set('view engine', 'ejs');
app.engine('html', require('ejs').renderFile);

app.use(express.json());
app.use(express.urlencoded({ extended: true}));
app.use(express.static(__dirname + '/public'));

/////////////////////////////////////////////////////////////////////////
//
// internal data
//
var leds  = [{"name": "가로등1", "id": 1, "lng": 126.887341, "lat": 37.478962, "brightness": 0, "status": 1}, {"name": "가로등2", "id": 2, "lng": 126.886161, "lat": 37.480018, "brightness": 0, "status": 1}];
var cctv  = [{"name": "카메라4", "id": 4, "lng": 126.887086, "lat": 37.478869, "azimuth": 60, "ptz":1 }, {"name": "카메라5", "id": 5, "lng": 126.886385, "lat": 37.480093, "azimuth": 250, "ptz":0 }];
var users = new Map()

/////////////////////////////////////////////////////////////////////////
//
// IPC w/ websocket
//
wss.on('connection', function connection(s, req, client) {
  console.log('connection from: %s', req.connection.remoteAddress);
  s.on('message', function incoming(message) {
    console.log('received: %s', message);
  });
  //w.send('something');
});

function sendWebsocket(message) {
  wss.clients.forEach(function each(client) {
    if (client.readyState === wsock.OPEN) {
      console.log('send: %s', message);
      client.send(message);
    }
  });
}

/////////////////////////////////////////////////////////////////////////
//
// middleware
//
app.use(function (req, res, next) {
    req.timestamp  = moment().unix();
    req.receivedAt = moment().tz('Asia/Seoul').format('YYYY-MM-DD hh:mm:ss');
    console.log(req.receivedAt + ': ', req.method, req.protocol +'://' + req.hostname + req.url);
  
    return next();
});

var host    = '192.168.137.4';
var stream4 = getStream('rtsp://192.168.137.4/Master-0?profile=Master-0&om',  9004, { '-vf': 'scale=420:286', '-stats': '', '-r': 20 });
var stream5 = getStream('rtsp://admin:4321@192.168.137.5/profile2/media.smp', 9005, { '-vf': 'hflip, vflip, scale=420:286', '-stats': '', '-r': 20 });
getGeoJson();

/////////////////////////////////////////////////////////////////////////
//
// route
//
app.get('/', function(req, res, next) {
  res.render('dashboard');
});

app.get('/dashboard', function(req, res, next) {
  res.render('dashboard');
});

app.get('/cctv/:id', function(req, res, next) {
    res.render('cctv', {port: "900" + req.params.id});
});

app.get('/map', function(req, res, next){
  res.render('map');
});

app.get('/map/route/:from/:to', function(req, res, next) {
  getRoute(req.params.from, req.params.to, function(data) {
    res.send(data);
  });
});

app.get('/trace/:user/:location', function(req, res, next) {
  if (users.has(req.params.user) == true) { users.delete(req.params.user); }
  users.set(req.params.user, req.params.location);

  getGeoJson();
  res.send(req.params.user);
});

app.post('/report/led/:id/:brightness', function(req, res, next){
  leds[req.params.id - 1].brightness = req.params.brightness;
  res.send(req.params.brightness);
});

app.post('/alert/led/:id', function(req, res, next) {
  leds[req.params.id - 1].status = 0;
  sendSMS('LED#' + req.params.id + ' push button cliecked.', '01038590916');
  res.send(req.params.id);
});

app.post('/alert/mic/:id', function(req, res, next) {
  leds[req.params.id - 1].status = 0;
  sendSMS('LED#' + req.params.id + ' hurry-up. ', '01038590916');
  res.send(req.params.brightness);
});

app.get('/cctv/:id/:action', function(req, res, next){
  ptzAct(host, req.params.action);
  res.send(req.params.action);
});

app.get('/geojson', function(req, res, next){
  getGeoJson();
  res.send('Hi');
});


/////////////////////////////////////////////////////////////////////////
//
// functions
//
function sendSMS(s, to) {
    request({
      method: 'POST',
      json: true,
      uri: `https://api-sens.ncloud.com/v1/sms/services/ncp:sms:kr:256512379353:rapid-alert/messages`,
      headers: { 'Content-Type': 'application/json', 'X-NCP-auth-key': '4bh1xKJRPx0V2MAknS3j', 'X-NCP-service-secret': 'f2b78c5e8f964e029ef81b66628b5851' },
      body: { type: 'sms', from: '01029368514', to: [to], content: s }
    });
}

function getStream (url, port, opts) {
  return new stream({ name: 'name', streamUrl: url, wsPort: port, ffmpegOptions: opts });
}

function ptzXml(channel, key, value) {
  return '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/"><soapenv:Header/><soapenv:Body><tem:ControlPTZ><tem:channel>'+
          channel + '</tem:channel><tem:param><tem:Parameter_T><tem:key>' + key + '</tem:key><tem:value>' +
          value + '</tem:value></tem:Parameter_T></tem:param></tem:ControlPTZ></soapenv:Body></soapenv:Envelope>';
}

function ptzAct(host, action) {
  const soapRequest = require('easy-soap-request');
  var   timeout = 1000;
  var   angle   = 45;

  switch(action) {
  case "left":
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Move', 'Left'),  timeout);
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Stop', 'Move'),  timeout);
    cctv[0].azimuth = (360 + cctv[0].azimuth - angle) % 360;
    break;
  case "right":
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Move', 'Right'), timeout);
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Stop', 'Move'),  timeout);
    cctv[0].azimuth = (360 + cctv[0].azimuth + angle) % 360;
    break;
  case "up":
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Move', 'Up'),    timeout);
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Stop', 'Move'),  timeout);
    break;
  case "down":
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Move', 'Down'),  timeout);
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Stop', 'Move'),  timeout);
    break;  
  case "tele":
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Zoom', 'tele0'),  timeout);
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Stop', 'Zoom'),   timeout);
    break;  
  case "wide":
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Zoom', 'wide0'),  timeout);
    soapRequest('http://' + host + '/soap', { 'Content-Type': 'application/xml', 'Authorization': 'Basic YWRtaW46YWRtaW4=' }, ptzXml(0, 'Stop', 'Zoom'),   timeout);
    break;    
  }

  getGeoJson();
}

function getRoute(from, to, callback) {
  var url = "https://map.naver.com/findroute2/findWalkRoute.nhn?call=route2&output=json&coord_type=naver&search=0&start=" + from + "&destination=" + to;
  console.log(url);
  var obj = request(url, function(error, response, body) {
      var json  = JSON.parse(body);
      var route =  json.result.route;
      var path  = [];
      route.forEach(r => {
          var point = r.point;
          point.forEach(p => {
              var position = {'x': p.x, 'y': p.y};
              path.push(position);
          });
      });
      console.log(path);
      return callback(JSON.stringify(path));
  });
}

function getGeoJson() {
  var obj = {
    "type": "FeatureCollection",
    "features": []
  }
  for(var i=0; i<leds.length; i++) {
    console.log(leds[i]);
    var point = {
      "type": "Feature",
      "properties": { "name": leds[i].name, "type": "LED", "id": leds[i].id, "brightness": leds[i].brightness, "status": leds[i].status },
      "geometry": { "type": "Point", "coordinates": [leds[i].lng, leds[i].lat]}
    }
    obj.features.push(point);
  }
  for(var i=0; i<cctv.length; i++) {
    console.log(cctv[i]);
    var point = {
      "type": "Feature",
      "properties": { "name": cctv[i].name, "type": "CCTV", "id": cctv[i].id, "azimuth": cctv[i].azimuth, "ptz": cctv[i].ptz },
      "geometry": { "type": "Point", "coordinates": [cctv[i].lng, cctv[i].lat]}
    }
    obj.features.push(point);
  }
  users.forEach( function(value, key, map) {
    console.log(key + ':' + value);
    var xy = value.split(",");
    var point = {
      "type": "Feature",
      "properties": { "type": "USER", "id": parseInt(key) },
      "geometry": { "type": "Point", "coordinates": [parseFloat(xy[0]), parseFloat(xy[1]) ]}
    }
    obj.features.push(point);
  });

  var data = JSON.stringify(obj);
  console.log(data);
  //fs.writeFile('http://localhost:' + port + '/data/geo.json', data, 'utf8', function(error) {
  fs.writeFile('./public/data/geo.json', data, 'utf8', function(error) {
    console.log('http://localhost:' + port + '/data/geo.json');
    console.log('Completed. file writing.');
  });

  sendWebsocket('hi');
}

////////////////////////////////////////////////////////
// listener
app.listen(port, function(){
    console.log('Listener: ', 'Example app listening on port ' + port);
});
module.exports = app;