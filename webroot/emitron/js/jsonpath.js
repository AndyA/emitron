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
    re: /^"(([^\\"]+|\\.)*)"/,
    t: 'str'
  },
  {
    re: /^'(([^\\']+|\\.)*)'/,
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
          var part = tok.m[0].split(':');
          while (part.length) m.push(part.shift() * 1);
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

  function mkSliceIter(from, to, step) {
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
    k.sort(); // mainly to make testing easier
    return k;
  }

  function mkKeyIter(obj) {
    if (obj instanceof Array) return mkSliceIter(0, obj.length);
    return mkListIter(getKeys(obj));
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
      return key >= from && key < to && (key - from) % step == 0;
    },
    function(obj) {
      return mkSliceIter(from, to, step);
    });
  }

  function mkMulti(pp) {
    if (pp.length == 1) return pp[0];
    return new JSONPathNode(function(key) {
      for (var i = 0; i < pp.length; i++) {
        if (pp[i].match(key)) return true;
      }
      return false;
    },
    function(obj) {
      if (pp.length == 0) return mkListIter([]);
      var i = 0;
      var ii = pp[i++].iter(obj);
      return function() {
        while (1) {
          var nv = ii();
          if (nv !== null) return nv;
          if (i == pp.length) return null;
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
    return mkMulti(pp);
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
  },
  match: function(path) {
    var pp = this.getPath().slice();
    if (! (path.substring && /^\$(?:\.\w+)*$/.test(path))) {
      throw "match needs a simple path";
    }
    var mp = path.split('.');
    while (pp.length && mp.length) {
      if (!pp.shift().match(mp.shift())) return null;
    }
    if (pp.length) return null;
    return mp;
  },
};

function JSONVisitor(data) {
  this.data = {
    '$': data
  };
}

JSONVisitor.bless = function(path) {
  if (path instanceof JSONVisitor) return path;
  return new JSONVisitor(path);
}

JSONVisitor.prototype = {
  getData: function() {
    return this.data['$'];
  },
  iter: function(path) {
    var p = JSONPath.bless(path).getPath();
    var pi = [];
    var pv = [];
    var pd = [this.data];
    var ipos = 0;
    var vpos = 0;
    var v;
    return function() {
      while (vpos < p.length) {
        while (ipos <= vpos) {
          pi[ipos] = p[ipos].iter(pd[ipos]);
          ipos++;
        }
        v = pi[vpos]();
        if (v === null) {
          if (vpos == 0) return null;
          ipos = vpos--;
        }
        else {
          if (pd[vpos] == null) return null;
          pv[vpos++] = v;
          pd[vpos] = pd[vpos - 1][v];
        }
      }
      var key = pv[vpos - 1];
      var ctx = pd[vpos - 1];
      if (ctx instanceof Array) key *= 1;
      // path, value, context, key
      var rv = [pv.join('.'), pd[vpos], ctx, key];
      vpos--;
      return rv;
    }
  },
  each: function(path, cb) {
    var ii = this.iter(path);
    for (var i = ii(); i !== null; i = ii()) cb.apply(this, i);
  }
}
