// Tests for JSONPath
module("JSONPath");
test("parse", function() {
  var p = new JSONPath({});
  raises(function() {
    p.parse('');
  },
  /Sorry/, 'Exception on empty path');
  deepEqual(p.parse('$'), ['$'], 'Parsed $');
  deepEqual(p.parse('$.foo'), ['$', 'foo'], 'Parsed $.foo');
  deepEqual(p.parse('$.foo.0.bar'), ['$', 'foo', '0', 'bar'], 'Parsed $.foo.0.bar');
});

test("visit", function() {
  var data = {
    seq: ['first', {
      index: 2
    },
    3],
    name: 'sequence'
  };
  var rec = new Recorder();
  var p = new JSONPath(data);
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
  var p = new JSONPath(data);
  p.each('$.seq.0', rec.callback());
  deepEqual(rec.getLog(), [
    ['first']], 'each');
});
