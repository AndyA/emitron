var model = new JSONTrigger({});

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
    //    console.log("[model]", data);
    model.setData(data);
  });

  ev.on('model-patch', function(ev, data) {
    //    console.log("[model-patch]", data);
    model.patch(data);
  });

  model.on('$.streams.*.INR.*', function(path, before, after, name, app) {
    if (before && !after) {
      var id = name + '_preview';
      $('#' + id).remove();
    }

    if (!before && after) {
      var id = name + '_preview';
      $('#main').append($('<div class="thumb_player"></div>').append($('<div></div>').attr({
        id: id
      })));
      var flashvars = {
        src: after.preview,
        autoPlay: true,
        controlBarAutoHide: true,
      };

      var parameters = {
        allowFullScreen: "true"
      };

      var attr = {
        name: name
      };

      swfobject.embedSWF("StrobeMediaPlayback.swf", id, 256, 144, //
      "10.1.0", "expressInstall.swf", flashvars, parameters, attr);
    }
  });

  ev.listen();
});
