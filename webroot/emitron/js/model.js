function Model(data) {
  this.p = new JSONPatch();
  this.t = new JSONTrigger();
  if (data) this.setData(data);
}

Model.prototype = {
  setData: function(data) {
    var prev = this.visitor;
    this.visitor = new JSONVisitor(data);
    this.p.setData(this.visitor);
    this.t.setData(this.visitor);
    if (prev) this.t.trigger(new JSONDiff().diff(prev.getData(), data));
  },
  getData: function() {
    return this.visitor.getData();
  },
  patch: function(jp) {
    this.p.patch(jp);
    this.t.trigger(jp);
  },
  on: function(path, cb) {
    this.t.on(path, cb);
  },
  subscribe: function(ev) {
    var self = this;
    ev.on('model', function(ev, data) {
      self.setData(data);
      console.log("Data replaced: ", self.getData());
    });

    ev.on('model-patch', function(ev, data) {
      self.patch(data);
      console.log("Data patched: ", data, self.getData());
    });
  }
}
