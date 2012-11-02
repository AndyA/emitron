// Tests for Model
module("Model");

dataDrivenTest("model", 'data/model.json', function(tc, tn) {
  var m = new Model(tc.data);
  var rec = new Recorder();
  for (var i = 0; i < tc.on.length; i++) m.on(tc.on[i], rec.callback());
  if (tc.patch) m.patch(tc.patch);
  else if (tc.newdata) m.setData(tc.newdata);
  deepEqual(rec.getLog(), tc.want, tc.name + ": model");
});
