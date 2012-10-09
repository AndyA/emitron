$(function() {
  var $clock = $('#clock');
  var clock = $clock.get(0);

  function timeOfDay() {
    var now = new Date();
    return (now.getTime() / 1000 - now.getTimezoneOffset() * 60) % (24*60*60);
  }

  $clock.on('loadeddata', function(e) {
    clock.currentTime = timeOfDay();
    clock.play();
  });
});
