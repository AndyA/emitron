window.CLOSURE_NO_DEPS = true;
(function() {
  var d = !0,
  j = !1;
  function k(a, b, e) {
    this.key = a;
    this.value = b;
    this.c = e
  }
  k.prototype.getKey = function() {
    return this.key
  };
  function t(a) {
    return a ? (a ^ 16 * Math.random() >> a / 4).toString(16) : ([1E7] + -1E3 + -4E3 + -8E3 + -1E11).replace(/[018]/g, t)
  }
  function u() {
    for (var a = document.cookie.split(";"), b = 0; b < a.length; b++) {
      var e = a[b].substr(0, a[b].indexOf("=")),
      f = a[b].substr(a[b].indexOf("=") + 1),
      e = e.replace(/^\s+|\s+$/g, "");
      if ("__jwpusr" == e) return unescape(f)
    }
  }
  function v(a) {
    var b = [];
    b.push("__jwpusr=" + escape(a));
    a = new Date;
    a.setDate(a.getDate() + 365);
    b.push("expires=" + a.toUTCString());
    b.push("path=/");
    document.cookie = b.join(";")
  }
  function w(a, b) {
    if (a == document) return d;
    if (!a || !a.parentNode || 0 === a.offsetWidth || 0 === a.offsetHeight) return j;
    var e = [];
    a.style && e.push(a.style);
    window.getComputedStyle && e.push(window.getComputedStyle(a, ""));
    a.currentStyle && e.push(a.currentStyle);
    for (var f = 0; f < e.length; f++) for (var c = 0; c < b.length; c++) {
      var g = b[c].key;
      if (("opacity" == g ? parseFloat(e[f][g]) : e[f][g]) === b[c].value) return j
    }
    return w(a.parentNode, b)
  }
  function x(a, b) {
    var e = document.getElementById(a),
    f = [{
      key: "visibility",
      value: "hidden"
    },
    {
      key: "display",
      value: "none"
    }];
    b || f.push({
      key: "opacity",
      value: 0
    });
    var c;
    a: {
      c = e.getBoundingClientRect();
      if (c = document.elementFromPoint((c.left + c.right) / 2, (c.top + c.bottom) / 2)) for (; c != document;) {
        if (c == e) {
          c = d;
          break a
        }
        c = c.parentNode
      }
      c = j
    }
    return c && w(e, f)
  };
  function y() {
    if (window._jwplayertracker) return window._jwplayertracker;
    window._jwplayertracker = this;
    this.b = {};
    this.l = "jwpltx.com";
    this.f = this.d = "n";
    this.k = "v1/jwplayer6/ping.gif?";
    this.j = window.jwplayer.version;
    this.i = window.location.href;
    this.h = document.title;
    this.g = document.referrer;
    this.e = top === self ? 0 : 1;
    this.m = 2882
  }
  function z(a, b, e, f, c, g) {
    a.b[f] || (a.b[f] = {});
    a.b[f][c] || (a.b[f][c] = {});
    b = A(a, b, e, f, c, g);
    a.b[f][c][b] && (b += "&dup=1");
    (new Image).src = b;
    a.b[f][c][b] = d
  }
  function A(a, b, e, f, c, g) {
    e = [new k("tv", a.m, 0), new k("dt", Math.round((new Date).getTime() / 1E3), 1), new k("n", ("0000000000000000" + Math.random().toString().substring(2)).slice(-16), 2), new k("uc", e, 3), new k("aid", f, 4), new k("e", c, 5), new k("i", a.e, 6), new k("pv", a.j, 7), new k("pu", a.i, 8), new k("pt", a.h, 100), new k("r", a.g, 200)];
    0 < g.length && (e = e.concat(g));
    e.sort(function(a, b) {
      return a.c > b.c ? 1 : -1
    });
    g = [];
    for (f = 0; f < e.length; f++) g.push(e[f].getKey() + "=" + encodeURIComponent(e[f].value));
    return["https:" == document.location.protocol ? "https://s." : "http://i.", b ? a.d : a.f, ".", a.l, "/", a.k, g.join("&")].join("")
  }
  function B(a) {
    for (var b in a.b) if (a.b[b].pv) return d;
    return j
  };
  function C(a) {
    this.a = a
  }
  function D(a, b) {
    a.a.onReady(b)
  }
  function E(a, b) {
    a.a.onIdle(b)
  }
  function F(a, b) {
    a.a.onPlaylistItem(b)
  }
  function G(a, b) {
    a.a.onPlay(b)
  }
  function H(a) {
    return a.a.getRenderingMode()
  }
  function I(a) {
    return a.a.config.autostart ? a.a.config.autostart : j
  };
  function J(a, b) {
    if (b.enabled !== j) {
      var e, f = 0;
      if (window.jwplayer.key) {
        var c = new window.jwplayer.utils.key(window.jwplayer.key),
        g = c.edition();
        "invalid" != g && (e = c.token());
        f = "invalid" == g ? 4 : "ads" == g ? 3 : "premium" == g ? 2 : "pro" == g ? 1 : 0
      }
      e || (e = "_");
      var r = j,
      i = new C(a),
      p = d;
      "undefined" != typeof b.cookies && (p = b.cookies ? d : j);
      var m;
      navigator.cookieEnabled === j ? m = "-" : p === j ? m = "_" : (c = u(), "undefined" == typeof c ? (c = t(), v(c), m = c == u() ? c : "0") : m = c);
      var s = new y;
      B(s) || z(s, p, m, e, "pv", [new k("ed", f, 20)]);
      D(i, function() {
        var a = "html5" == H(i).toLowerCase();
        z(s, p, m, e, "e", [new k("m", "html5" == H(i).toLowerCase() ? 1 : 0, 10), new k("a", "true" == I(i).toString().toLowerCase() ? 1 : 0, 11), new k("v", x(i.a.id, a) ? 1 : 0, 12), new k("w", i.a.getWidth(), 13), new k("h", i.a.getHeight(), 14), new k("ed", f, 20)])
      });
      E(i, function() {
        r = d
      });
      F(i, function() {
        r = d
      });
      G(i, function() {
        if (r) {
          r = j;
          var a = i.a.getPlaylist(),
          b = i.a.getPlaylistItem(),
          c = b.file;
          if (b.sources) {
            for (var g = [], l = b.sources.length - 1; 0 <= l; l--) b.sources[l].url ? g.push(b.sources[l].url) : b.sources[l].file && g.push(b.sources[l].file);
            g.sort();
            c = g[0]
          }
          var g = p,
          l = m,
          K = e,
          L = new k("m", "html5" == H(i).toLowerCase() ? 1 : 0, 10),
          M = new k("a", "true" == I(i).toString().toLowerCase() ? 1 : 0, 11),
          N = new k("v", x(i.a.id, j) ? 1 : 0, 12),
          O = new k("w", i.a.getWidth(), 13),
          P = new k("h", i.a.getHeight(), 14),
          Q = new k("f", i.a.getFullscreen() ? 1 : 0, 15),
          a = new k("pl", a.length, 16),
          R = new k("l", b.duration, 17),
          h;
          var n = c.indexOf("://"),
          q = c.indexOf("?");
          if (0 < n && (0 > q || q > n)) h = c;
          else {
            h || (h = document.location.href);
            n = h.substring(0, h.indexOf("://") + 3);
            q = h.substring(n.length, h.indexOf("/", n.length + 1));
            0 === c.indexOf("/") ? h = c.split("/") : (h = h.split("?")[0], h = h.substring(n.length + q.length + 1, h.lastIndexOf("/")), h = h.split("/").concat(c.split("/")));
            for (var c = [], o = 0; o < h.length; o++) h[o] && "." != h[o] && (".." == h[o] ? c.pop() : c.push(h[o]));
            h = n + q + "/" + c.join("/")
          }
          z(s, g, l, K, "s", [L, M, N, O, P, Q, a, R, new k("mu", h, 18), new k("t", b.title, 19), new k("ed", f, 20), new k("id", b.mediaid, 101), new k("k", b.tags, 102), new k("lu", b.link, 103), new k("d", b.description, 201)])
        }
      })
    }
  }
  window.jwplayer && window.jwplayer() && window.jwplayer().registerPlugin("jwpsrv", "6.0", J);
})();
