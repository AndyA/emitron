$(function() {

  var asset = ["media/commentary.m4a", "media/millwall.m4a", "media/wigan.m4a"];
  var source = [];

  function getAudioContext() {
    if (typeof AudioContext !== "undefined") return new AudioContext();
    if (typeof webkitAudioContext !== "undefined") return new webkitAudioContext();
    return null;
  }

  function loadAudio(url, cb) {
    var rq = new XMLHttpRequest();
    rq.open("GET", url, true);
    rq.responseType = "arraybuffer";
    rq.addEventListener('load', function(evt) {
      cb(evt.target.response);
    },
    false);
    rq.send();
  }

  var context = getAudioContext();

  var j = new Join(function() {
    console.log("All loaded");
    for (var i = 0; i < source.length; i++) {
      console.log("Play " + i);
      source[i].connect(context.destination);
      source[i].noteOn(0);
    }
  });

  for (var i = 0; i < asset.length; i++) {
    (function(url, cb) {
      loadAudio(url, function(data) {
        var src = context.createBufferSource();
        src.buffer = context.createBuffer(data, false);
        source.push(src);
        console.log("Loaded " + url);
        cb();
      });
    })(asset[i], j.getCallback());
  }

});
