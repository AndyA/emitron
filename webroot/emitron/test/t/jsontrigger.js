// Tests for JSONTrigger
module("JSONTrigger");

test("fire", function() {
  var jt = new JSONTrigger();
  var rec = new Recorder();

  jt.on('$.foo', rec.callback());
  jt.on('$.bar.*', rec.callback()).on('*$.*.bink', rec.callback(), 'aGroup');

  function fire() {
    jt.fire('$.foo.0', "Hello, World").fire('$.bar.boffle', 1, 2, 3);
    jt.fire('$.baz.bink');
    jt.fire('$.baz.nomatch');
    jt.fire('$.bar.bink');
  }

  fire();

  (function() {
    var want = [
      ['$.foo.0', "Hello, World"],
      ['$.bar.boffle', 1, 2, 3],
      ['$.baz.bink'],
      ['$.bar.bink'],
      ['$.bar.bink']];

    deepEqual(rec.getLog(), want, "fire");
  })();

  jt.off({
    path: '$.foo'
  }).off({
    group: 'aGroup'
  });

  fire();

  (function() {
    var want = [
      ['$.bar.boffle', 1, 2, 3],
      ['$.bar.bink']];

    deepEqual(rec.getLog(), want, "fire after off()");
  })();

});

dataDrivenTest("changeSet", 'data/trigger.json#changeSet', function(tc) {
  var jt = new JSONTrigger(tc.data);
  var cs = jt.changeSet(tc.patch);
  deepEqual(cs.list.getData(), tc.list, tc.name + ": list");
});

dataDrivenTest("trigger", 'data/trigger.json#trigger', function(tc, tn) {
  var jt = new JSONTrigger(tc.data);
  var rec = new Recorder();
  for (var i = 0; i < tc.on.length; i++) {
    jt.on(tc.on[i], rec.callback());
  }
  jt.patch(tc.patch);
  deepEqual(rec.getLog(), tc.want, tc.name + ": trigger");
});

dataDrivenTest("model", 'data/trigger.json#model', function(tc, tn) {
  var m = new JSONTrigger(tc.data);
  var rec = new Recorder();
  for (var i = 0; i < tc.on.length; i++) {
    m.on(tc.on[i], rec.callback());
  }
  if (tc.patch) m.patch(tc.patch);
  else if (tc.newdata) m.setData(tc.newdata);
  deepEqual(rec.getLog(), tc.want, tc.name + ": model");
});

function testPatch(tc) {
  var p = new JSONTrigger(tc.a);
  p.patch(tc.diff);
  deepEqual(p.getData(), tc.b, tc.name);
}

dataDrivenTest('patch', 'data/diffpatch.json', testPatch);
dataDrivenTest('patch (non diff data)', 'data/patchonly.json', testPatch);
