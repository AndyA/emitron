function TestData() {}

TestData.data = {};
TestData.cacheBust = new Date().getTime();

TestData.withData = function(url, cb) {
  var octo = url.indexOf('#');
  if (octo >= 0) {
    var frag = url.substr(octo + 1);
    url = url.substr(0, octo);
    var ocb = cb;
    cb = function(data) {
      ocb(data[frag]);
    }
  }

  function callback(data) {
    // Clone data
    cb($.extend(true, (data instanceof Array ? [] : {}), data));
  }

  if (this.data.hasOwnProperty(url)) {
    callback(this.data[url]);
    return;
  }

  $.get(url + '?_=' + this.cacheBust, function(data) {
    TestData.data[url] = data;
    callback(data);
  });
}

function dataDrivenTest(name, url, cb, opt) {
  var before = function() {};
  var after = before;
  var clone = {};
  if (opt && opt.readOnly) {
    before = function(d, n) {
      clone = $.extend(true, ({}), d);
    }
    after = function(d, b) {
      deepEqual(d, clone, "input unchanged");
    }
  }
  asyncTest(name, function() {
    TestData.withData(url, function(data) {
      if (data.length == 0) expect(0);
      for (var tn = 0; tn < data.length; tn++) {
        var tc = data[tn];
        if (!tc.disabled) {
          before(tc, tn);
          cb(tc, tn);
          after(tc, tn);
        }
      }
      start();
    });
  });
}
