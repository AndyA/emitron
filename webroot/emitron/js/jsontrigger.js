function JSONTrigger(data) {
  this.init(data);
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

  function clone(obj) {
    if (obj.substring || obj.toFixed) return obj;
    return $.extend(true, (obj instanceof Array ? [] : {}), obj);
  }

  var $super = JSONPatch.prototype;

  return $.extend(({}), $super, {
    init: function(data) {
      this.handler = [];
      $super.setData.apply(this, [data == null ? {} : data]);
    },
    // TODO: properly modelling changes in arrays requires this code
    // to be integrated with the patch code - cos correct intepretation
    // of array changes needs the array to be mutated.
    changeSet: function(jp) {
      var list = new JSONVisitor({});
      var orig = new JSONVisitor(clone(this.getData()));

      for (var i = 0; i < jp.length; i++) {
        var pp = jp[i];
        var path = this.patchPath(pp);
        switch (pp.op) {
        case "add":
          visit(pp.value, function(pa, val) {
            setBit(list, pa, 2);
          },
          [path]);
          break;
        case "remove":
          this.p.each(path, function(p, v, c, k) {
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
        orig: orig
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
        var $this = this;
        cs.list.each(h.pp, function(p, v, c, k) {
          var flags = 0;
          visit(v, function(path, value) {
            flags |= value;
          });

          if (flags) {
            var before = cs.orig.get(h.pp);
            var after = $this.p.get(h.pp);
            if (before != null || after != null) {
              h.cb.apply($this, [h.path, before, after]);
            }
          }
        });
      }
    },
    patch: function(jp) {
      var cs = this.changeSet(jp);
      $super.patch.apply(this, [jp]);
      this.triggerSet(cs);
    },
    setData: function(data) {
      var diff = new JSONDiff().diff(this.getData(), data);
      var cs = this.changeSet(diff);
      $super.setData.apply(this, [data]);
      this.triggerSet(cs);
    },
    trigger: function(jp) {
      this.triggerSet(this.changeSet(jp));
    },
  });
})();
