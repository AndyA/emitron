$(function() {
  var $live = $('#live');
  var live = $live[0];

  $live.bind('timeupdate', function(e) {
    console.log('ct:', live.currentTime);
  });

});
