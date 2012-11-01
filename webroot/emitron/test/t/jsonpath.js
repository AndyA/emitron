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
});

test("iter", function() {
  var data = [{
    name: 'Root only',
    in:{},
    path: '$',
    want: ['$']
  },
  {
    name: 'Slice',
    in:[],
    path: '$[0:3]',
    want: ['$.0', '$.1', '$.2']
  }];

  expect(data.length * 2);
  for (var tn = 0; tn < data.length; tn++) {
    var tc = data[tn];
    var p = new JSONVisitor(tc. in );
    var got = [];
    var ii = p.iter(tc.path);
    for (var i = 0; i < tc.want.length; i++) got.push(ii()[3]);
    deepEqual(got, tc.want, tc.name + ": iter");
    deepEqual(ii(), null, tc.name + ": iter exhausted");
  }

});

module("JSONVisitor");
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
    want: [
      ['first', ['first', {
        index: 2
      },
      3], "0"]]
  },
  {
    name: 'Complex concrete path',
    in:in1,
    path: '$["seq"][0]',
    want: [
      ['first', ['first', {
        index: 2
      },
      3], "0"]]
  },
  {
    name: 'Wildcard',
    in:in1,
    path: '$[*]',
    want: [
      [
        ['first', {
          index: 2
        },
        3], in1, "seq"],
      ['sequence', in1, "name"]]
  }];
  expect(data.length);
  for (var tn = 0; tn < data.length; tn++) {
    var tc = data[tn];
    var rec = new Recorder();
    var p = new JSONVisitor(tc. in );
    p.each(tc.path, rec.callback());
    deepEqual(rec.getLog(), tc.want, tc.name + ": each");
  }

});
