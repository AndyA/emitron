function JSONPath(data) {
  this.data = {
    '$': data
  };
}

JSONPath.prototype = {
  parse: function(path) {
    if (/^\$(?:\.\w+)*$/.test(path)) {
      return path.split('.');
    }
    throw "Sorry, I don't handle full JSONPath yet";
  },
  getData: function() {
    return this.data['$'];
  },
  // Visit every matching element in the data structure.
  // The callback gets the following args:
  //   * container        The containing object
  //   * key              The key of the target object
  visit: function(path, cb) {
    var p = this.parse(path);
    var dp = this.data;
    while (p.length > 1) {
      var key = p.shift();
      dp = dp[key];
    }
    cb(dp, p.shift());
  },
  each: function(path, cb) {
    this.visit(path, function(container, key) {
      cb(container[key]);
    });
  }
}
