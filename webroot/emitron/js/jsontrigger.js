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

  var $super = JSONPatch.prototype;

  return $.extend(({}), $super, {
    // TODO: properly modelling changes in arrays requires this code
    // to be integrated with the patch code - cos correct intepretation
    // of array changes needs the array to be mutated.
    changeSet: function(jp) {
      var before = new JSONVisitor({});
      var after = new JSONVisitor({});
      var union = new JSONVisitor({});
      for (var i = 0; i < jp.length; i++) {
        var pp = jp[i];
        var path = this.patchPath(pp);
        switch (pp.op) {
        case "add":
          after.set(path, pp.value);
          union.set(path, pp.value);
          break;
        case "remove":
          this.p.each(path, function(p, v, c, k) {
            before.set(p, v);
            union.set(p, v);
          });
          break;
        }
      }
      return {
        before: before,
        after: after,
        union: union
      };
    },
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
    patch: function(jp) {
      $super.patch.apply(this, [jp]);
      this.trigger(jp);
    },
    trigger: function(jp) {
      var hh = this.handler;
      var hit = [];
      for (var i = 0; i < hh.length; i++) hit[i] = {};
      for (i = 0; i < jp.length; i++) {
        var pp = jp[i];
        var path = this.patchPath(pp);
        // TODO if we're adding an object we should walk
        // into it expanding any paths it contains
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
