// Tests for JSONDiff
module("JSONDiff");

asyncTest("diff", function() {
  TestData.withData('data/diffpatch.json', function(data) {
    expect(data.length);
    for (var tn = 0; tn < data.length; tn++) {
      var tc = data[tn];
      var d = new JSONDiff().diff(tc.a, tc.b);
      deepEqual(d, tc.diff, tc.name);
    }
    start();
  });
});
