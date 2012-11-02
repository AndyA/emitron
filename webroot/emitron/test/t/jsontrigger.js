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

dataDrivenTest("trigger", 'data/trigger.json', function(tc, tn) {
  var jt = new JSONTrigger(tc.data);
  var rec = new Recorder();
  for (var i = 0; i < tc.on.length; i++) {
    jt.on(tc.on[i], rec.callback());
  }
  jt.trigger(tc.patch);
  deepEqual(rec.getLog(), tc.want, tc.name + ": trigger");

});
