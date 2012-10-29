$(function() {
  var here = new URLParser(window.location.href);
  var api = here.root() + '/api';
  var ev = new EV(api + '/ev');
  ev.on('test', function(ev, data) {
    console.log("Got message: " + ev);
  });
  ev.on('error', function(ev, data) {
    var msg = "Error";
    if (data.status) msg += ": " + data.status;
    if (data.error) msg += " (" + data.error + ")";
    console.log(msg);
  });
  ev.listen();
});
