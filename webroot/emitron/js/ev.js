function EV(endpoint) {
  this.endpoint = endpoint;
  this.evmap = {};
  this.uptime = 0;
  this.downtime = 0;
}

EV.prototype = {
  on: function(evsig, cb) {
    // This will need to get a little more subtle
    this.evmap[evsig] = cb;
  },
  _despatch: function(ev) {
    if (this.evmap.hasOwnProperty(ev.name)) {
      this.evmap[ev.name](ev.name, ev.data);
      return;
    }
    console.log("Discarding unhandled event: " + ev.name);
  },
  makeEvent: function(name, data) {
    return {
      name: name,
      data: data
    };
  },
  _makeRequest: function() {
    $.ajax({
      url: this.endpoint,
      cache: false,
      context: this,
      dataType: 'json',
      global: false,
      success: this._success,
      error: this._error,
    });
  },
  _success: function(data, status, xhr) {
    this.uptime++;
    this.downtime = 0;
    this._despatch(data);
    this._makeRequest();
  },
  _error: function(xhr, status, error) {
    this.uptime = 0;
    this.downtime++;
    var ev = this.makeEvent('error', {
      status: status,
      error: error
    });
    this._despatch(ev);
    var backoff = 1000 * Math.pow(Math.sqrt(2), this.downtime);
    if (backoff > 60000) backoff = 60000;
    var self = this;
    setTimeout(function() {
      self._makeRequest();
    },
    backoff);
  },
  // Start the listener polling
  listen: function() {
    this._makeRequest();
  },
}
