// Tests for Join
module("Join");

test("log", function() {
  var done = 0;

  var j = new Join(function() {
    done++;
  });

  equal(done, 0, "init 0");

  var cb1 = j.getCallback();
  var cb2 = j.getCallback();

  equal(done, 0, "still 0");

  cb1();

  equal(done, 0, "still 0");

  var cb3 = j.getCallback();

  equal(done, 0, "still 0");

  cb3();

  equal(done, 0, "still 0");

  cb2();

  equal(done, 1, "joined");

  cb1(); cb2(); cb3();

  equal(done, 1, "joined only once");
});
