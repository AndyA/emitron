var model = new JSONPatch({});

$(function() {
  var here = new URLParser(window.location.href);
  var api = here.root() + '/api';
  var ev = new EV(api + '/ev/');

  ev.on('test', function(ev, data) {
    console.log("Got message: " + ev + ": " + data.sequence);
  });
  ev.on('error', function(ev, data) {
    var msg = "Error";
    if (data.status) msg += ": " + data.status;
    if (data.error) msg += " (" + data.error + ")";
    console.log(msg);
  });

  ev.on('model', function(ev, data) {
    model.setData(data);
    console.log("Data replaced: " + JSON.stringify(model.getData(), null, 2));
  });

  ev.on('model-patch', function(ev, data) {
    model.patch(data);
    console.log("Data patched: " + JSON.stringify(data, null, 2) + ", " + JSON.stringify(model.getData(), null, 2));
  });

  ev.listen();
});
