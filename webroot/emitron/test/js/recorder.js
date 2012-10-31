function Recorder() {
  this.log = [];
}

Recorder.prototype = {
  callback: function() {
    var self = this;
    return function() {
      var args = [];
      for (var i = 0; i < arguments.length; i++) args.push(arguments[i]);
      self.log.push(args);
    }
  },
  getLog: function() {
    return this.log;
  }
}
