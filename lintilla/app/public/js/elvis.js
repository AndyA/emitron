Use of uninitialized value $comment in concatenation(.) or string at / home / andy / perl5 / perlbrew / perls / perl - 5.16.0 / lib / site_perl / 5.16.0 / JavaScript / Beautifier.pm line 571,
<STDIN > line 1.
$(function() {
  var here = new URLParser(window.location.href);

  function getJson(url, cb) {
    $.ajax({
      url: url,
      context: this,
      dataType: 'json',
      global: false,
      success: cb
    });
  }

  function boxFit(iw, ih, maxw, maxh) {
    var scale = Math.min(maxw / iw, maxh / ih);
    var sz = [Math.floor(iw * scale), Math.floor(ih * scale)];
    return sz;
  }

  function imageURL(db, img, variant) {
    var tail = '/' + img[0] + '/' + img[1] + '.jpg';
    if (!variant || variant == 'full') return db.path + '/' + img[0] + '/' + img[1] + '.jpg';
    return db.path + '/' + img[0] + '/var/' + variant + '/' + img[1] + '.jpg';
  }

  getJson('/config/recipe', function(recipe) {
    console.log(recipe);
    getJson('/catalogue.json', function(db) {
      var $c = $('#content');
      var imgs = db.img;
      for (var i = 0; i < imgs.length && i < 30; i++) {
        var iurl = imageURL(db, imgs[i], 'slice');
        $c.append($('<img></img>').attr({
          class: 'slice',
          src: iurl
        }));
      }
    });
  });

});
