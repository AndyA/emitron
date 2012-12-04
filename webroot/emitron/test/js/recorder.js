function Recorder() {
  this.log = [];
}

Recorder.prototype = {
  callback: function() {
    var self = this;
    return function() {
      var args = [];
      for (var i = 0; i < arguments.length; i++) {
        // promote undefined to null for ease of testing against
        // literal JSON data.
        args.push(arguments[i] == null ? null : arguments[i]);
      }
      self.log.push(args);
    }
  },
  getLog: function() {
    var rc = this.log;
    this.log = [];
    return rc;
  }
}
