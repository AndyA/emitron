var cheat;
$(function() {
  var $clock = $('#clock');
  var clock = $clock[0];

  var RTMP = 'rtmp://newstream.hexten.net/vod/mp4:clock-5.mp4';

  function timeOfDay() {
    var now = new Date();
    return (now.getTime() / 1000 - now.getTimezoneOffset() * 60) % (24 * 60 * 60);
  }

  $clock.on('canplay', function(e) {
    clock.currentTime = timeOfDay();
    clock.play();
    $clock.off('canplay');
  });

  // Force Flash if HLS unlikely
  if (!clock.canPlayType('application/x-mpegURL')) {
    $('source', $clock).attr({
      src: RTMP,
      type: "video/x-flv"
    });
    $clock.mediaelementplayer({
      mode: 'shim',
      success: function(clock, node, player) {
        cheat = clock;
        clock.load();
        clock.play();
        var bootstrap = function(e) {
          clock.setCurrentTime(timeOfDay());
          clock.removeEventListener('canplay', bootstrap);
        }
        clock.addEventListener('canplay', bootstrap, false);
      }
    });
  }
});
