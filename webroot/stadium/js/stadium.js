$(function() {

  var track = [{
    url: "media/commentary.m4a",
    name: "commentary"
  },
  {
    url: "media/millwall.m4a",
    name: "millwall"
  },
  {
    url: "media/wigan.m4a",
    name: "wigan"
  }];

  var layout = {
    commentary: track[0],
    ends: [track[1], track[2]]
  };

  var SPEED_OF_SOUND = 340.29;
  var END_TO_END = 140; // Assume 100m pitch, mics set back 20m at each end
  var SIDE_TO_SIDE = 80; // Approx 80m apart at each end
  var MIN_DIST = (SIDE_TO_SIDE / 2);

  function positionToDistance(pos) {
    return (END_TO_END - MIN_DIST) * pos + MIN_DIST;
  }

  // Dist in the range 0 (west) to 1 (east)
  function positionToDelay(pos) {
    return positionToDistance(pos) / SPEED_OF_SOUND;
  }

  function positionToGain(pos) {
    var dist = positionToDistance(pos);
    // Inverse square
    return (MIN_DIST * MIN_DIST) / (dist * dist);
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

  function connectPipe() {
    for (var i = 1; i < arguments.length; i++) {
      arguments[i - 1].connect(arguments[i]);
    }
  }

  function wire() {
    for (var i = 0; i < track.length; i++) {
      track[i].gain = ctx.createGainNode();
      track[i].delay = ctx.createDelayNode(positionToDelay(1) * 2);
      connectPipe(track[i].src, track[i].delay, track[i].gain, ctx.destination);
    }
  }

  function makeSlider(elt, cb) {
    elt.append($('<div class="slider"></div>').slider({
      slide: function(evt, ui) {
        cb(ui.value / 100);
      }
    }));
    cb(0);
  }

  function setPosition(t, pos) {
    t.gain.gain.value = positionToGain(pos);
    t.delay.delayTime.value = positionToDelay(pos);
    console.log(t.name + ": gain=", t.gain.gain.value, ", delay=", t.delay.delayTime.value);
  }

  function buildInterface() {
    var $controls = $('#controls');

    makeSlider($controls, function(value) {
      layout.commentary.gain.gain.value = value;
    });

    makeSlider($controls, function(value) {
      setPosition(layout.ends[0], value);
      setPosition(layout.ends[1], 1 - value);
    });
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

  function init() {
    var j = new Join(function() {
      console.log("All loaded");
      $('#play').click(play);
      $('#stop').click(stop);
      wire();
      buildInterface();
    });

    for (var i = 0; i < track.length; i++) {
      (function(t, cb) {
        loadAudio(t.url, function(data) {
          t.src = ctx.createBufferSource();
          t.src.buffer = ctx.createBuffer(data, false);
          console.log("Loaded " + t.url);
          cb();
        });
      })(track[i], j.getCallback());
    }
  }

  var ctx = getAudioContext();
  init();

});
