function URLParser(url, args) {
  this.parse(url, args);
}

URLParser.prototype = {
  parse: function(url, args) {
    var url_re = new RegExp('^([a-z]+)://([^/]*)(/[^?#]*)?(\\?.*?)?(#.*)?$');
    var rs = url_re.exec(url);
    if (rs == null) {
      throw "Bad URL";
    }
    this.parts = {
      scheme: rs[1],
      host: rs[2],
      path: rs[3]
    };
    if (rs[4] != null) {
      this.parts.query = rs[4].substring(1);
    }
    if (rs[5] != null) {
      this.parts.frag = rs[5].substring(1);
    }
    this.args = $.extend({},
    args || {});
    if (this.parts.query != null) {
      var aa = this.parts.query.split('&');
      for (i in aa) {
        var nv = aa[i].split('=', 2);
        this.args[unescape(nv[0])] = unescape(nv[1]);
      }
    }
    return this;
  },
  part: function() {
    if (arguments.length > 1) {
      this.parts[arguments[0]] = arguments[1];
    }
    else {
      return this.parts[arguments[0]];
    }
  },
  toString: function() {
    var u = this.parts.scheme + '://' + this.parts.host + this.parts.path;
    if (this.parts.query != null) {
      u += '?' + this.parts.query;
    }
    if (this.parts.frag != null) {
      u += '#' + this.parts.frag;
    }
    return u;
  },
  makeAbsolute: function(rel) {
    if (rel.match(/^[a-z]+:/)) {
      return new URLParser(rel);
    }
    if (!rel.match(/^\//)) {
      var path = this.parts.path.replace(/\/[^\/]*$/, '');
      rel = path + '/' + rel;
    }
    return new URLParser(this.parts.scheme + '://' + this.parts.host + rel);
  }
}
