var model = new Model({});

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
  });

  ev.on('model-patch', function(ev, data) {
    model.patch(data);
  });

  model.on('$.args', function() {
    $('#main').append($('<pre></pre>').text(model.getData().args.join(' '))).append($('<br></br>'));
  });

  model.on('$.streams', function(path, delta) {
    console.log('path: ', path);
    console.log('delta: ', delta);
    model.each('$.streams.*', function(path, data) {
      console.log(path, ": ", data);
    });
  });

  ev.listen();
});
