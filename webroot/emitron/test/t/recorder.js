// Tests for Recorder
module("Recorder");
test("log", function() {
  var rec = new Recorder();
  var cb = rec.callback();
  cb(1, 2, 3);
  cb({
    foo: 1
  },
  "Hello");
  cb();
  deepEqual(rec.getLog(), [
    [1, 2, 3],
    [{
      foo: 1
    },
    "Hello"],
    [], ], 'calls recorded');
});
