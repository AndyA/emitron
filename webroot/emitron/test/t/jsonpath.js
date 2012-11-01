// Tests for JSONPath
module("JSONPath");

function testToker(path, want) {
  var t = JSONPath.toker(path);

  for (var i = 0; i < want.length; i++) {
    var tok = t();
    deepEqual(tok, want[i], "token " + tok.m[0]);
  }

  deepEqual(t(), null, "end of tokens");
}

test("toker", function() {
  testToker('$', [{
    t: 'lit',
    m: ['$', '$']
  }]);
  testToker('foo', [{
    t: 'lit',
    m: ['foo', 'foo']
  }]);
  testToker('$.foo', [{
    t: 'lit',
    m: ['$', '$']
  },
  {
    t: 'dot',
    m: ['.']
  },
  {
    t: 'lit',
    m: ['foo', 'foo']
  },
  ]);
  testToker('$["root"][0][\'leaf\']', [{
    t: 'lit',
    m: ['$', '$']
  },
  {
    t: 'lb',
    m: ['[']
  },
  {
    t: 'str',
    m: ['"root"', 'root']
  },
  {
    t: 'rb',
    m: [']']
  },
  {
    t: 'lb',
    m: ['[']
  },
  {
    t: 'lit',
    m: ['0', '0']
  },
  {
    t: 'rb',
    m: [']']
  },
  {
    t: 'lb',
    m: ['[']
  },
  {
    t: 'str',
    m: ["'leaf'", 'leaf']
  },
  {
    t: 'rb',
    m: [']']
  }]);
  testToker('""', [{
    t: 'str',
    m: ['""', '']
  }]);
  testToker('"\\n\\x41\\101"', [{
    t: 'str',
    m: ['"\\n\\x41\\101"', '\nAA']
  }]);
  testToker('^', [{
    t: 'unknown',
    m: ['^']
  }]);
  testToker('10:100', [{
    t: 'slice',
    m: ['10:100', 10, 100]
  }]);
  testToker('10:100:2', [{
    t: 'slice',
    m: ['10:100:2', 10, 100, 2]
  }]);
  testToker('"foo","bar"', [{
    t: 'str',
    m: ['"foo"', 'foo']
  },
  {
    t: 'comma',
    m: [',']
  },
  {
    t: 'str',
    m: ['"bar"', 'bar']
  }]);
});

test("match", function() {
  var data = [{
    name: 'Exact',
    path: '$.a.b',
    test: '$.a.b',
    want: []
  },
  {
    name: 'Submatch',
    path: '$.a.b',
    test: '$.a.b.c',
    want: ['c']
  },
  {
    name: 'Slice',
    path: '$[4:12:3]',
    test: '$.7',
    want: []
  },
  {
    name: 'Slice miss',
    path: '$[4:12:3]',
    test: '$.6',
    want: null
  },
  {
    name: 'Slice outside range',
    path: '$[4:12:3]',
    test: '$.13',
    want: null
  },
  {
    name: 'Alternation',
    path: '$["foo","bar"]',
    test: '$.bar',
    want: []
  }];
  for (var tn = 0; tn < data.length; tn++) {
    var tc = data[tn];
    var jp = new JSONPath(tc.path);
    var got = jp.match(tc.test);
    deepEqual(got, tc.want, tc.name + ": " + tc.path + " ?= " + tc.test);
  }
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

test("iter", function() {
  var data = [{
    name: 'Root only',
    data: {},
    path: '$',
    want: ['$']
  },
  {
    name: 'Slice',
    data: [],
    path: '$[0:3]',
    want: ['$.0', '$.1', '$.2']
  },
  {
    name: 'Wildcard',
    data: {
      foo: 1,
      bar: 2,
      baz: 3
    },
    path: '$[*]',
    want: ['$.bar', '$.baz', '$.foo']
  },
  {
    name: 'Wildcard, slice, sequence',
    data: {
      foo: [],
      bar: [],
      baz: []
    },
    path: '$[*][0:4,10:20:2,99]',
    want: [ // (comments to force formatting)
    '$.bar.0', '$.bar.1', '$.bar.2', '$.bar.3', //
    '$.bar.10', '$.bar.12', '$.bar.14', '$.bar.16', //
    '$.bar.18', '$.bar.99', //
    '$.baz.0', '$.baz.1', '$.baz.2', '$.baz.3', //
    '$.baz.10', '$.baz.12', '$.baz.14', '$.baz.16', //
    '$.baz.18', '$.baz.99', //
    '$.foo.0', '$.foo.1', '$.foo.2', '$.foo.3', //
    '$.foo.10', '$.foo.12', '$.foo.14', '$.foo.16', //
    '$.foo.18', '$.foo.99']
  },
  {
    name: 'Missing key',
    data: {
      foo: 1
    },
    path: '$.bar',
    want: ['$.bar']
  },
  {
    name: 'Deeply missing',
    data: {},
    path: '$.foo.bar',
    want: []
  }];

  for (var tn = 0; tn < data.length; tn++) {
    var tc = data[tn];
    var p = new JSONVisitor(tc.data);
    var ii = p.iter(tc.path);
    for (var i = 0; i < tc.want.length; i++) {
      var want = resolve_path(tc.data, tc.want[i]);
      var got = ii();
      deepEqual(got, want, tc.name + ": " + tc.want[i]);
    }
    deepEqual(ii(), null, tc.name + ": iter exhausted");
  }

});

test("each", function() {
  var in1 = {
    seq: ['first', {
      index: 2
    },
    3],
    name: 'sequence'
  };
  var data = [{
    name: 'Simple concrete path',
    in:in1,
    path: '$.seq.0',
    want: ['$.seq.0']
  },
  {
    name: 'Complex concrete path',
    in:in1,
    path: '$["seq"][0]',
    want: ['$.seq.0']
  }];
  expect(data.length);
  for (var tn = 0; tn < data.length; tn++) {
    var tc = data[tn];
    var rec = new Recorder();
    var p = new JSONVisitor(tc. in );
    var want = [];
    for (var i = 0; i < tc.want.length; i++) {
      want.push(resolve_path(tc. in , tc.want[i]));
    }
    p.each(tc.path, rec.callback());
    deepEqual(rec.getLog(), want, tc.name + ": each");
  }

});
