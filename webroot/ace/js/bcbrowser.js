$(function() {
  var here = new URLParser(window.location.href);
  var svc = here.makeAbsolute('svc/barcode.php');
  var cat = {};

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

  var media_id = null;
  var media_ready = false;
  var media_pending = [];

  function when_ready(cb) {
    if (media_ready) cb();
    else media_pending.push(cb);
  }

  function switch_media(id, xp, yp) {
    console.log("switch_media(\"" + id + "\", " + xp + ", " + yp + ")");
    if (id != media_id) {
      media_ready = false;
      media_pending = [];
      media_id = id;
      console.log("Loading " + cat[id].media);
      $('#player').attr({
        src: cat[id].media
      });
      //        empty().append($('<source></source>').attr({
      //        src: cat[id].media
      //      }));
    }
    when_ready(function() {
      var player = $('#player')[0];
      player.currentTime = player.duration * xp;
    });
  }

  $('#player').bind('loadedmetadata', function(e) {
    console.log("Got some metadata");
    media_ready = true;
    for (var i = 0; i < media_pending.length; i++) {
      (media_pending[i])()
    }
    media_pending = [];
  });

  get_json(svc, function(data, status, xhr) {
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
