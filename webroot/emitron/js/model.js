function Model(data) {
  this.t = new JSONTrigger();
  if (data) this.setData(data);
}

Model.prototype = {
  setData: function(data) {
    var prev = this.visitor;
    this.visitor = new JSONVisitor(data);
    this.t.setData(this.visitor);
    if (prev) this.t.trigger(new JSONDiff().diff(prev.getData(), data));
  },
  each: function(path, cb) {
    this.visitor.each(path, cb);
  },
  getData: function() {
    return this.visitor.getData();
  },
  patch: function(jp) {
    this.t.patch(jp);
    this.t.trigger(jp);
  },
  on: function(path, cb) {
    this.t.on(path, cb);
  }
}
