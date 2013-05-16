function Join(cb) {
  this.cb = cb;
  this.id = 1;
  this.reg = {};
}

Join.prototype = {
  getCallback: function() {
    var id = 'x' + this.id++;
    var reg = this.reg;
    var cb = this.cb;
    reg[id] = true;
    return function() {
      if (!(id in reg)) return;
      delete reg[id];
      for (var x in reg) if (reg.hasOwnProperty(x)) return;
      cb();
    }
  }
}
