// Tests for JSONDiff
module("JSONDiff");

test("diff", function() {
  // TODO share data with jsonpatch
  var data = [{
    name: "Type change/hash",
    a: {
      bar: "two",
      foo: 1
    },
    b: {
      bar: [1, 2, 3],
      foo: 1
    },
    diff: [{
      path: "$.bar",
      op: "remove"
    },
    {
      value: [1, 2, 3],
      path: "$",
      element: "bar",
      op: "add"
    }]
  },
  {
    name: "Hash",
    a: {
      bar: "two",
      foo: 1
    },
    b: {
      bar: "three",
      foo: 1
    },
    diff: [{
      path: "$.bar",
      op: "remove"
    },
    {
      value: "three",
      path: "$",
      element: "bar",
      op: "add"
    }]
  },
  {
    name: "Array",
    a: [1, 2, 3],
    b: [1, 3, 2],
    diff: [{
      path: "$.1",
      op: "remove"
    },
    {
      value: 3,
      path: "$",
      element: 1,
      op: "add"
    },
    {
      path: "$.2",
      op: "remove"
    },
    {
      value: 2,
      path: "$",
      element: 2,
      op: "add"
    }]
  },
  {
    name: "Root scalar",
    a: "One",
    b: 2,
    diff: [{
      path: "$",
      op: "remove"
    },
    {
      value: 2,
      element: "$",
      op: "add"
    }]
  },
  {
    name: "Add key",
    a: {},
    b: {
      args: ["Snoofus?"]
    },
    diff: [{
      value: ["Snoofus?"],
      path: "$",
      element: "args",
      op: "add"
    }]
  },
  {
    name: "Empty array",
    a: {
      args: ["Hello", "World"]
    },
    b: {
      args: []
    },
    diff: [{
      path: "$.args.0",
      op: "remove"
    },
    {
      path: "$.args.0",
      op: "remove"
    }]
  }];

  expect(data.length);
  for (var tn = 0; tn < data.length; tn++) {
    var tc = data[tn];
    var d = new JSONDiff().diff(tc.a, tc.b);
    deepEqual(d, tc.diff, tc.name);
  }
});
