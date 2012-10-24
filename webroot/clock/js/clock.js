var player = null;

function onSMPCallback(playerId) {
  if (player == null) {
    player = document.getElementById(playerId);
    player.addEventListener("mediaPlayerStateChange", "onMediaPlayerStateChange");
  }
}

function timeOfDay() {
  var now = new Date();
  return (now.getTime() / 1000 - now.getTimezoneOffset() * 60) % (24 * 60 * 60);
}

function onMediaPlayerStateChange(state, playerId) {
  if (state == 'ready') {
    player.seek(timeOfDay());
    player.removeEventListener('mediaPlayerStateChange');
  }
}

$(function() {
  var here = new URLParser(window.location.href);
  var hls_mime = 'application/x-mpegURL';
  var m3u8 = "clock.m3u8";
  var f4m = "hds/clock.f4m";

  var $clock = $('#clock');
  var clock = $clock[0];

  function inTimeRange(tr, tm) {
    for (var i = 0; i < tr.length; i++) {
      if (tm >= tr.start(i) && tm < tr.end(i)) return true;
    }
    return false;
  }

  function deferredSeek(elt, tm) {
    var now = tm();
    if (inTimeRange(elt.seekable, now)) {
      elt.currentTime = now;
      return;
    }

    var onTime = function(time) {
      var now = tm();
      if (inTimeRange(elt.seekable, now)) {
        elt.currentTime = now;
        elt.removeEventListener('timeupdate', onTime, false);
        return;
      }
    }

    elt.addEventListener('timeupdate', onTime, false);
  }

  if (clock.canPlayType(hls_mime)) {
    // HTML5 + HLS
    $clock.append($("<source></source>").attr({
      src: m3u8,
      type: hls_mime
    })).attr({
      controls: 'controls',
      autoplay: 'autoplay',
      loop: 'loop',
    });
    deferredSeek(clock, timeOfDay);
  }
  else {
    // Replace video element with Flash player
    var flashvars = {
      src: here.makeAbsolute(f4m),
      autoPlay: true,
      controlBarAutoHide: true,
      loop: true,
      javascriptCallbackFunction: "onSMPCallback"
    };

    var parameters = {
      allowFullScreen: "true"
    };

    var attr = {
      name: "clock"
    };

    swfobject.embedSWF("StrobeMediaPlayback.swf", "clock", 960, 320, "10.1.0", "expressInstall.swf", flashvars, parameters, attr);
  }

});
