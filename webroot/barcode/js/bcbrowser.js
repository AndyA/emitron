$(function() {
  var here = new URLParser(window.location.href);
  var svc = here.makeAbsolute('svc/barcode.php');
  var cat = {};

  var media_id = null;
  var mp = new MagicPlayer('player', {
    width: 1024,
    height: 576
  });

  function mk_id() {
    return Array.prototype.slice.call(arguments, 0).join('__');
  }

  function parse_id(id) {
    return id.split('__');
  }

  function get_json(url, cb) {
    $.ajax({
      url: url,
      context: this,
      dataType: 'json',
      global: false,
      success: cb
    });
  }

  function switch_media(id, xp, yp) {
    console.log("switch_media(\"" + id + "\", " + xp + ", " + yp + ")");
    if (id != media_id) {
      media_id = id;
      console.log("Loading " + cat[id].media);
      mp.load({
        file: cat[id].media,
//        seekScaled: 0.5,
        seek: 200,
      });
      $('#nav').attr({
        src: cat[id].full
      });
    }
  }

  get_json(svc, function(data) {
    var dock = $('#dock');
    for (var i = 0; i < data.length; i++) {
      var name = data[i].name;
      cat[name] = data[i];
      var id = mk_id(name, 'thumb');
      dock.append($('<div></div>').attr({
        class: "wrap"
      }).append($('<img></img>').attr({
        id: id,
        src: data[i].thumb
      })));
    }

    $('#dock img').click(function(e) {
      var $this = $(this);
      var id = parse_id($this.attr('id')).shift();
      var offset = $this.offset();
      var cx = e.pageX - offset.left;
      var cy = e.pageY - offset.top;
      switch_media(id, cx / this.width, cy / this.height);
    });

  });
});
