function TestData() {}

TestData.data = {};

TestData.withData = function(url, cb) {
  function callback(data) {
    // Clone data
    cb($.extend(true, (data instanceof Array ? [] : {}), data));
  }

  if (this.data.hasOwnProperty(url)) {
    callback(this.data[url]);
    return;
  }

  $.get(url, function(data) {
    TestData.data[url] = data;
    callback(data);
  });
}
