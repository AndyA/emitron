function EV(endpoint) {
  this.endpoint = endpoint;
  this.evmap = {};
}

EV.prototype = {
  on: function(evsig, cb) {},
  // Start the listener polling
  listen: function() {},
}
