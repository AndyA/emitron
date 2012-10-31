// Tests for JSONPath
module("JSONPath");
test("parse", function() {
  raises(function() {
    JSONPath.parse('');
  },
  /Sorry/, 'Exception on empty path');
  deepEqual(JSONPath.parse('$'), ['$'], 'Parsed $');
  deepEqual(JSONPath.parse('$.foo'), ['$', 'foo'], 'Parsed $.foo');
  deepEqual(JSONPath.parse('$.foo.0.bar'), ['$', 'foo', '0', 'bar'], 'Parsed $.foo.0.bar');
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
