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
    m: ['10:100', '10', '100']
  }]);
  testToker('10:100:2', [{
    t: 'slice',
    m: ['10:100:2', '10', '100', '2']
  }]);
});

//test("parse", function() {
//  raises(function() {
//    JSONPath.parse('');
//  },
//  /Empty/, 'Exception on empty path');
//  deepEqual(JSONPath.parse('$'), ['$'], 'Parsed $');
//  deepEqual(JSONPath.parse('$.foo'), ['$', 'foo'], 'Parsed $.foo');
//  deepEqual(JSONPath.parse('$.foo.0.bar'), ['$', 'foo', '0', 'bar'], 'Parsed $.foo.0.bar');
//});
module("JSONVisitor");
test("visit", function() {
  var data = {
    seq: ['first', {
      index: 2
    },
    3],
    name: 'sequence'
  };
  var rec = new Recorder();
  var p = new JSONVisitor(data);
  p.visit('$.seq.0', rec.callback());
  deepEqual(rec.getLog(), [
    [
      ['first', {
        index: 2
      },
      3], "0"]], 'visit');
});

test("each", function() {
  var data = {
    seq: ['first', {
      index: 2
    },
    3],
    name: 'sequence'
  };
  var rec = new Recorder();
  var p = new JSONVisitor(data);
  p.each('$.seq.0', rec.callback());
  deepEqual(rec.getLog(), [
    ['first']], 'each');
});
