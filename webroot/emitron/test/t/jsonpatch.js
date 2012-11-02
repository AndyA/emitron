// Tests for JSONPatch
module("JSONPatch");
test("basic", function() {
  var p = new JSONPatch({
    foo: 1
  });
  deepEqual(p.getData(), {
    foo: 1
  },
  'getData');
  p.setData([]);
  deepEqual(p.getData(), [], 'setData');
});

test("patchPath", function() {
  var p = new JSONPatch({});
  deepEqual(p.patchPath({
    path: '$.foo'
  }), '$.foo');
  deepEqual(p.patchPath({
    element: '$.foo'
  }), '$.foo');
  deepEqual(p.patchPath({
    path: '$',
    element: 'foo'
  }), '$.foo');
});

asyncTest("patch", function() {
  function testPatch(data) {
    for (var tn = 0; tn < data.length; tn++) {
      var tc = data[tn];
      var p = new JSONPatch(tc.a);
      p.patch(tc.diff);
      deepEqual(p.getData(), tc.b, tc.name);
    }
    start();
  }
  TestData.withData('data/diffpatch.json', testPatch);
  TestData.withData('data/patchonly.json', testPatch);
});
