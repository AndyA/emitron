function JSONTrigger(data) {
  this.handler = [];
  if (data) this.setData(data);
}

JSONTrigger.prototype = (function() {

  function getKeys(obj) {
    var k = [];
    for (var key in obj) if (obj.hasOwnProperty(key)) k.push(key);
    k.sort(); // mainly to make testing easier
    return k;
  }

  return $.extend(({}), JSONPatch.prototype, {
    on: function(path, cb) {
      var pp = JSONPath.bless(path);
      this.handler.push({
        path: path,
        pp: pp,
        cb: cb
      });
    },
    fire: function(path) {
      var hh = this.handler;
      for (var i = 0; i < hh.length; i++) {
        var h = hh[i];
        if (h.pp.match(path)) h.cb.apply(this, arguments);
      }
    },
    trigger: function(jp) {
      var hh = this.handler;
      var hit = [];
      for (var i = 0; i < hh.length; i++) hit[i] = {};
      for (i = 0; i < jp.length; i++) {
        var pp = jp[i];
        var path = this.patchPath(pp);
        for (var j = 0; j < hh.length; j++) {
          var h = hh[j];
          var m = h.pp.match(path);
          if (m) hit[j][m.join('.')] = true;
        }
      }
      for (i = 0; i < hh.length; i++) {
        var m = getKeys(hit[i]);
        if (m.length) {
          var h = hh[i];
          h.cb.apply(this, [h.path, m]);
        }
      }
    },
  });
})();
