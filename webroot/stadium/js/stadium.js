$(function() {

  var asset = ["media/commentary.m4a", "media/millwall.m4a", "media/wigan.m4a"];
  var track = [];

  var SPEED_OF_SOUND = 340.29;
  var END_TO_END = 140; // Assume 100m pitch, mics set back 20m at each end
  var SIDE_TO_SIDE = 80; // Approx 80m apart at each end
  // Dist in the range 0 (west) to 1 (east)
  function distanceToDelay(dist) {
    return (END_TO_END * dist) / SPEED_OF_SOUND;
  }

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

  function wire() {
    for (var i = 0; i < track.length; i++) {
      track[i].gain = ctx.createGainNode();
      track[i].src.connect(track[i].gain);
      track[i].gain.connect(ctx.destination);
    }
  }

  function buildInterface() {
    var $controls = $('#controls');
    for (var i = 0; i < track.length; i++) {
      (function(t) {
        $controls.append($('<div class="slider"></div>').slider({
          range: true,
          slide: function(evt, ui) {
            console.log(t.name, ": ", ui.value);
            t.gain.gain.value = ui.value / 100;
          }
        }));
      })(track[i]);
    }
  }

  function play() {
    for (var i = 0; i < track.length; i++) {
      track[i].src.noteOn(0);
    }
  }

  function stop() {
    for (var i = 0; i < track.length; i++) {
      track[i].src.noteOff(0);
    }
  }

  $('#play').click(play);
  $('#stop').click(stop);

  var ctx = getAudioContext();

  var j = new Join(function() {
    console.log("All loaded");
    wire();
    buildInterface();
  });

  for (var i = 0; i < asset.length; i++) {
    (function(url, cb) {
      loadAudio(url, function(data) {
        var src = ctx.createBufferSource();
        src.buffer = ctx.createBuffer(data, false);
        track.push({
          src: src,
          name: url.replace(/([^\/\.]+)\.[^\/\.]+$/, '$1'),
          url: url
        });
        console.log("Loaded " + url);
        cb();
      });
    })(asset[i], j.getCallback());
  }

});
