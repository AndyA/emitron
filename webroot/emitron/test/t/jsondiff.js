// Tests for JSONDiff
module("JSONDiff");

dataDrivenTest("diff", 'data/diffpatch.json', function(tc, tn) {
  var d = new JSONDiff().diff(tc.a, tc.b);
  deepEqual(d, tc.diff, tc.name);
},
{
  readOnly: true
});
