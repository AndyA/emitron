function Model(data) {
  this.t = new JSONTrigger();
  if (data) this.setData(data);
}

Model.prototype = {
  setData: function(data) {
    var diff = new JSONDiff().diff(this.getData(), data);
    var cs = this.t.changeSet(diff);
    this.t.setData(data);
    this.t.triggerSet(cs);
  },
  each: function(path, cb) {
    this.t.p.each(path, cb);
  },
  getData: function() {
    return this.t.getData();
  },
  patch: function(jp) {
    this.t.patch(jp);
  },
  on: function(path, cb) {
    this.t.on(path, cb);
  }
}
