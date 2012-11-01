// http://goessner.net/articles/JsonPath/
function JSONPath(path) {
  if (path) this.parse(path);
}

JSONPath.bless = function(path) {
  if (path instanceof JSONPath) return path;
  return new JSONPath(path);
}

JSONPath.nibbler = function(path, tokmatch) {
  var buf = path;
  return function() {
    if (buf.length == 0) return null;
    for (var i = 0; i < tokmatch.length; i++) {
      var tm = tokmatch[i];
      var m = tm.re.exec(buf);
      if (m) {
        buf = buf.substring(m[0].length);
        return {
          t: tm.t,
          m: m
        };
      }
    }
    var r = {
      t: 'unknown',
      m: [buf]
    };
    buf = '';
    return r;
  }
}

JSONPath.toker = (function() {
  var escmap = {
    'b': '\b',
    'f': '\f',
    'n': '\n',
    'r': '\r',
    't': '\t',
    'v': '\v',
    '"': '\"',
    '\'': '\'',
    '\\': '\\'
  }

  var esc = /\\([bfnrtv"'\\]|[0-3][0-7]{2}|x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4})/g;

  var tokmatch = [{
    re: /^\d+:\d+(?::\d+)?/,
    t: 'slice'
  },
  {
    re: /^(\w+|\$)/,
    t: 'lit'
  },
  {
    re: /^\.\./,
    t: 'dotdot'
  },
  {
    re: /^\./,
    t: 'dot'
  },
  {
    re: /^\*/,
    t: 'star'
  },
  {
    re: /^@/,
    t: 'at'
  },
  {
    re: /^\[/,
    t: 'lb'
  },
  {
    re: /^\]/,
    t: 'rb'
  },
  {
    re: /^,/,
    t: 'comma'
  },
  {
    re: /^\?\(/,
    t: 'lpq'
  },
  {
    re: /^\(/,
    t: 'lp'
  },
  {
    re: /^\)/,
    t: 'rp'
  },
  {
    re: /^"(([^\\]+|\\.)*)"/,
    t: 'str'
  },
  {
    re: /^'(([^\\]+|\\.)*)'/,
    t: 'str'
  }];

  function ppEscape(m, esc) {
    if (escmap.hasOwnProperty(esc)) return escmap[esc];
    if (/^[ux]/.test(esc)) return String.fromCharCode(parseInt(esc.substr(1), 16));
    if (/^[0-3]/.test(esc)) return String.fromCharCode(parseInt(esc, 8));
    return '\\' + esc;
  }

  function ppString(str) {
    return str.replace(esc, ppEscape);
  }

  return function(path) {
    var nib = JSONPath.nibbler(path, tokmatch);
    return function() {
      var tok = nib();
      if (tok) {
        switch (tok.t) {
        case 'str':
          return {
            t: 'str',
            m: [tok.m[0], ppString(tok.m[1])]
          };
        case 'slice':
          var m = [tok.m[0]];
          m.push.apply(m, tok.m[0].split(':'));
          return {
            t: 'slice',
            m: m
          };
        }
      }
      return tok;
    }
  }
})();

function JSONPathNode(match, iter) {
  this.match = match;
  this.iter = iter;
}

JSONPath.parse = (function() {
  function mkListIter(l) {
    var i = 0;
    return function() {
      if (i == l.length) return null;
      return l[i++];
    }
  }

  function mkCounter(from, to, step) {
    if (step == null) step = 1;
    return function() {
      var i = from;
      if (i >= to) return null;
      from += step;
      return i;
    }
  }

  function getKeys(obj) {
    var k = [];
    for (var key in obj) if (obj.hasOwnProperty(key)) k.push(key);
    return k;
  }

  function mkKeyIter(obj) {
    if (obj instanceof Array) return mkCounter(0, obj.length);
    return mkListIter(getKeys(obj));
  }

  function hasKey(obj, key) {
    if (obj instanceof Array) return key >= 0 && key < obj.length;
    return obj.hasOwnProperty(key);
  }

  function mkLiteral(t) {
    var v = t.m[1];
    return new JSONPathNode(function(key) {
      return key == v;
    },
    function(obj) {
      return mkListIter([v]);
    });
  }

  function mkAny(t) {
    return new JSONPathNode(function(key) {
      return true;
    },
    function(obj) {
      return mkKeyIter(obj);
    });
  }

  function mkSlice(t) {
    var from = t.m[1];
    var to = t.m[2];
    var step = t.m.length > 3 ? t.m[3] : 1;
    return new JSONPathNode(function(key) {
      return key >= from && key < to && key % step == 0;
    },
    function(obj) {
      return mkCounter(from, to, step);
    });
  }

  function mkMulti(pp) {
    return new JSONPathNode(function(key) {
      for (var i = 0; i < pp.length; i++) {
        if (pp.match(key)) return true;
      }
      return false;
    },
    function(obj) {
      if (pp.length == 0) return mkListIter([]);
      var i = 0;
      var ii = pp[i++].iter(obj);
      return function() {
        while (ii) {
          var nv = ii();
          if (nv !== null) return nv;
          ii = pp[i++].iter(obj);
        }
        return null;
      }
    });
  }

  function parseBrackets(tokr) {
    var t = tokr();
    var pp = [];
    while (t) {
      switch (t.t) {
      case 'slice':
        pp.push(mkSlice(t));
        break;
      case 'lit':
      case 'str':
        pp.push(mkLiteral(t));
        break;
      case 'star':
        pp.push(mkAny(t));
        break;
      default:
        throw "Syntax error: " + t.m[0];
      }
      t = tokr();
      if (!t) throw "Missing ]";
      if (t.t == 'rb') break;
      if (t.t != 'comma') throw "Syntax error: " + t.m[0];
      t = tokr();
    }
    if (pp.length == 0) throw "Empty []";
    if (pp.length == 1) return pp[0];
  }

  return function(path) {
    var tokr = JSONPath.toker(path);
    var t = tokr();
    if (!t) throw "Empty path";
    var pp = [];
    while (t) {
      switch (t.t) {
      case 'lit':
        pp.push(mkLiteral(t));
        break;
      case 'star':
        pp.push(mkAny(t));
        break;
      case 'dot':
        break;
      case 'lb':
        pp.push(parseBrackets(tokr));
        break;
      default:
        throw "Syntax error";
      }
      t = tokr();
    }
    return pp;
  }
})();

JSONPath.prototype = {
  parse: function(path) {
    this.path = JSONPath.parse(path);
  },
  getPath: function() {
    return this.path;
  }
};

function JSONVisitor(data) {
  this.data = {
    '$': data
  };
}

JSONVisitor.prototype = {
  getData: function() {
    return this.data['$'];
  },
  each: (function() {
    function expand(p, pos, obj, cb) {
      var ii = p[pos].iter(obj);
      if (pos < p.length - 1) {
        for (var key = ii(); key != null; key = ii()) {
          expand(p, pos + 1, obj[key], cb);
        }
        return;
      }
      // reached end of path
      for (var key = ii(); key != null; key = ii()) {
        cb(obj[key], obj, key);
      }
    }
    return function(path, cb) {
      expand(JSONPath.bless(path).getPath(), 0, this.data, cb);
    }
  })()
}
