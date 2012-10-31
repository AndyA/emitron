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
    // no match: error
    throw "JSONPath error: " + path.substring(0, path.length - buf.length) + " >>> " + buf;
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
      if (tok && tok.t == 'str') return {
        t: 'str',
        m: [tok.m[0], ppString(tok.m[1])]
      };
      return tok;
    }

    return JSONPath.nibbler(path, tokmatch);
  }
})();

// Parse a JSONPath expression. Returns a list that may contain a
// mixture of literal element keys and closures. Literal keys are
// simply used to index into the current object. Closures may be
// called with the current object; they will return an iterator
// that enumerates the selected keys within that object.
//
// The path may be relative (no leading '$')
JSONPath.parse = function(path) {
  if (/^\$(?:\.\w+)*$/.test(path)) {
    // fast case: a simple literal absolute path
    return path.split('.');
  }
  throw "Sorry, I don't handle full JSONPath yet";
}

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
  // Visit every matching element in the data structure.
  // The callback gets the following args:
  //   * container        The containing object
  //   * key              The key of the target object
  visit: function(path, cb) {
    var p = JSONPath.bless(path).getPath();
    var dp = this.data;
    while (p.length > 1) {
      var key = p.shift();
      dp = dp[key];
    }
    cb(dp, p.shift());
  },
  each: function(path, cb) {
    this.visit(path, function(container, key) {
      cb(container[key]);
    });
  }
}
