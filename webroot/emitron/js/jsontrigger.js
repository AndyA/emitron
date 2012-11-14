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

  function visit(obj, cb, path) {
    var empty = true;
    if (obj == null) return;
    if (!path) path = ['$'];

    if (obj instanceof Array) {
      for (var i = 0; i < obj.length; i++) {
        path.push(i);
        visit(obj[i], cb, path);
        path.pop();
      }
      return;
    }

    if (obj.substring || obj.toFixed) {
      cb(path.join('.'), obj);
      return;
    }

    for (var i in obj) {
      if (obj.hasOwnProperty(i)) {
        path.push(i);
        visit(obj[i], cb, path);
        path.pop();
        empty = false;
      }
    }

    if (empty) cb(path.join('.'), obj);
  }

  function setBit(v, path, bit) {
    v.each(path, function(p, v, ctx, key) {
      ctx[key] |= bit;
    },
    true);
  }

  var $super = JSONPatch.prototype;

  return $.extend(({}), $super, {
    // TODO: properly modelling changes in arrays requires this code
    // to be integrated with the patch code - cos correct intepretation
    // of array changes needs the array to be mutated.
    changeSet: function(jp) {
      var list = new JSONVisitor({});
      var before = new JSONVisitor({});
      var after = new JSONVisitor({});

      for (var i = 0; i < jp.length; i++) {
        var pp = jp[i];
        var path = this.patchPath(pp);
        switch (pp.op) {
        case "add":
          after.set(path, pp.value);
          visit(pp.value, function(pa, val) {
            setBit(list, pa, 2);
          },
          [path]);
          break;
        case "remove":
          this.p.each(path, function(p, v, c, k) {
            before.set(p, v);
            visit(v, function(pa, val) {
              setBit(list, pa, 1);
            },
            [path]);
          });
          break;
        }
      }
      return {
        list: list,
        before: before,
        after: after
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
    triggerSet: function(cs) {
      var hh = this.handler;

      for (var j = 0; j < hh.length; j++) {
        var h = hh[j];
        cs.list.each(h.pp, function(path, v, c, k) {
          var flags = 0;
          visit(v, function(p, value) {
            flags |= value;
          },
          []);
          if (flags) h.cb.apply(this, [path, flags]);
        });
      }
    },
    patch: function(jp) {
      var cs = this.changeSet(jp);
      $super.patch.apply(this, [jp]);
      this.triggerSet(cs);
    },
    trigger: function(jp) {
      this.triggerSet(this.changeSet(jp));
    },
  });
})();
