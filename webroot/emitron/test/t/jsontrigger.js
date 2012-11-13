// Tests for JSONTrigger
module("JSONTrigger");

test("fire", function() {
  var jt = new JSONTrigger();
  var rec = new Recorder();

  jt.on('$.foo', rec.callback());
  jt.on('$.bar.*', rec.callback());

  jt.fire('$.foo.0', "Hello, World");
  jt.fire('$.bar.boffle', 1, 2, 3);
  jt.fire('$.baz.nomatch');

  var want = [
    ['$.foo.0', "Hello, World"],
    ['$.bar.boffle', 1, 2, 3], ];

  deepEqual(rec.getLog(), want, "fire");
});

dataDrivenTest("trigger", 'data/trigger.json#trigger', function(tc, tn) {
  var jt = new JSONTrigger(tc.data);
  var rec = new Recorder();
  for (var i = 0; i < tc.on.length; i++) {
    jt.on(tc.on[i], rec.callback());
  }
  jt.trigger(tc.patch);
  deepEqual(rec.getLog(), tc.want, tc.name + ": trigger");
},
{
  readOnly: true
});

function testPatch(tc) {
  var p = new JSONTrigger(tc.a);
  p.patch(tc.diff);
  deepEqual(p.getData(), tc.b, tc.name);
}

dataDrivenTest('patch', 'data/diffpatch.json', testPatch);
dataDrivenTest('patch (non diff data)', 'data/patchonly.json', testPatch);

dataDrivenTest("changeSet", 'data/trigger.json#changeSet', function(tc) {
  var jt = new JSONTrigger(tc.data);
  var cs = jt.changeSet(tc.patch);
  deepEqual(cs.before.getData(), tc.before, tc.name + ": before");
  deepEqual(cs.after.getData(), tc.after, tc.name + ": after");
  deepEqual(cs.union.getData(), tc.union, tc.name + ": union");
});
