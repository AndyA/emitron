(function() {
  var log = console.log;
  console.log = function() {
    log.apply(this, arguments);
  }
})();
