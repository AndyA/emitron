// Tests for JSONPath
module("JSONPath");

dataDrivenTest("toker", "data/path.json#toker", function(tc) {
  var t = JSONPath.toker(tc.path);

  for (var i = 0; i < tc.want.length; i++) {
    var tok = t();
    deepEqual(tok, tc.want[i], "token " + tok.m[0]);
  }

  deepEqual(t(), null, "end of tokens");

});

dataDrivenTest("match", "data/path.json#match", function(tc) {
  var jp = new JSONPath(tc.path);
  var got = jp.match(tc.test);
  deepEqual(got, tc.want, tc.name + ": " + tc.path + " ?= " + tc.test);
});

module("JSONVisitor");

function resolve_path(data, path) {
  var pds = null;
  var p = path.split('.');
  var ds = {
    '$': data
  };
  var key;
  while (p.length) {
    pds = ds;
    key = p.shift();
    ds = ds[key];
  }
  if (pds instanceof Array) key *= 1;
  return[path, ds, pds, key];
}

dataDrivenTest("iter", "data/path.json#iter", function(tc) {
  var p = new JSONVisitor(tc.data);
  var ii = p.iter(tc.path);
  for (var i = 0; i < tc.want.length; i++) {
    var want = resolve_path(tc.data, tc.want[i]);
    var got = ii();
    deepEqual(got, want, tc.name + ": " + tc.want[i]);
  }
  deepEqual(ii(), null, tc.name + ": iter exhausted");
});

dataDrivenTest("each", "data/path.json#each", function(tc) {
  var rec = new Recorder();
  var p = new JSONVisitor(tc. in );
  var want = [];
  for (var i = 0; i < tc.want.length; i++) {
    want.push(resolve_path(tc. in , tc.want[i]));
  }
  p.each(tc.path, rec.callback());
  deepEqual(rec.getLog(), want, tc.name + ": each");
});
