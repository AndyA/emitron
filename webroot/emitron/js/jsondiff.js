function JSONDiff() {

}

JSONDiff.prototype = (function() {
  function type(obj) {
    if (obj == null) return 'null';
    if (obj.substring || obj.toFixed) return 'scalar';
    if (obj instanceof Array) return 'array';
    return 'object';
  }

  function keys(obj) {
    var k = [];
    for (var i in obj) if (obj.hasOwnProperty(i)) k.push(i);
    return k;
  }

  function uniq() {
    var seen = {};
    var l = [];
    for (var i = 0; i < arguments.length; i++) {
      var ar = arguments[i];
      for (var j = 0; j < ar.length; j++) {
        var v = ar[j];
        if (!seen.hasOwnProperty(v)) {
          l.push(v);
          seen[v] = true;
        }
      }
    }
    return l;
  }

  function diffwalk(da, db, path, cb) {
    var ta = type(da);
    var tb = type(db);
    if (ta == tb) {
      switch (ta) {
      case 'null':
        break;
      case 'scalar':
        if (da !== db) {
          cb('remove', path);
          cb('add', path, db);
        }
        break;
      case 'array':
        var mi = Math.min(da.length, db.length);
        for (var i = 0; i < mi; i++) {
          path.push(i);
          diffwalk(da[i], db[i], path, cb);
          path.pop();
        }
        for (i = da.length; i < db.length; i++) {
          path.push(i);
          cb('add', path, db[i]);
          path.pop();
        }
        path.push(db.length);
        for (i = db.length; i < da.length; i++) {
          cb('remove', path);
        }
        path.pop();
        break;
      case 'object':
        var k = uniq(keys(da), keys(db));
        for (var i = 0; i < k.length; i++) {
          var key = k[i];
          path.push(key);
          if (da.hasOwnProperty(key)) {
            if (db.hasOwnProperty(key)) diffwalk(da[key], db[key], path, cb);
            else cb('remove', path);
          }
          else {
            cb('add', path, db[key]);
          }
          path.pop();
        }
        break;
      }
    }
    else {
      cb('remove', path);
      cb('add', path, db);
    }
  }

  return {
    diff: function(da, db) {
      var d = [];
      diffwalk(da, db, ['$'], function(verb, path, value) {
        switch (verb) {
        case 'add':
          var p = path.slice();
          var e = p.pop();
          var rec = {
            op: 'add',
            element: e,
            value: value
          };
          if (p.length) rec.path = p.join('.');
          d.push(rec);
          break;
        case 'remove':
          d.push({
            op: 'remove',
            path: path.join('.')
          });
          break;
        }
      });
      return d;
    }
  };
})();
