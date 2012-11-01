function JSONPatch(data) {
  this.setData(data);
}

JSONPatch.prototype = {
  getData: function() {
    return this.p.getData();
  },
  setData: function(data) {
    this.p = new JSONVisitor(data);
  },
  patchPath: function(patch) {
    var p = [];
    if (patch.path != null) p.push(patch.path);
    if (patch.element != null) p.push(patch.element);
    return p.join('.');
  },
  patch: function(jp) {
    for (var i = 0; i < jp.length; i++) {
      var pp = jp[i];
      var path = this.patchPath(pp);
      switch (pp.op) {
      case 'add':
        this.p.each(path, function(p, v, elt, key) {
          if (elt instanceof Array) elt.splice(key, 0, pp.value);
          else elt[key] = pp.value;
        });
        break;
      case 'remove':
        this.p.each(path, function(p, v, elt, key) {
          if (elt instanceof Array) elt.splice(key, 1);
          else delete elt[key];
        });
        break;
      default:
        throw "Bad op: " + pp.op;
      }
    }
  },
}
