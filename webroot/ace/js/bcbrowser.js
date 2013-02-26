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
  var nav_width = $('#nav')[0].width;
  console.log("nav_width=" + nav_width);

  function when_ready(cb) {
    if (media_ready) cb();
    else media_pending.push(cb);
  }

  function scaler(inlo, inhi, outlo, outhi) {
    return function(n) {
      if (n < inlo) n = inlo;
      if (n > inhi) n = inhi;
      return (n - inlo) * (outhi - outlo) / (inhi - inlo) + outlo;
    };
  }

  function build_chapter(sc, cw, chap) {
    var left = Math.floor(sc(chap. in ));
    var right = Math.floor(sc(chap.out));
    var col = cw.next();
    var player = $('#player')[0];

    $('#chapters').append($('<div></div>').attr({
      class: "chapter"
    }).css({
      left: left + 'px',
      width: (right - left) + 'px',
      backgroundColor: col
    }).mouseenter(function(e) {
      $('#popup').show().text(chap.desc).css({
        borderColor: col
      }).position({
        my: 'bottom',
        at: 'top',
        of: '#chapters'
      });
    }).mouseleave(function(e) {
      $('#popup').hide();
    }).click(function(e) {
      player.currentTime = chap. in ;
    }));
  }

  function switch_media(id, xp, yp) {
    console.log("switch_media(\"" + id + "\", " + xp + ", " + yp + ")");
    if (id != media_id) {
      media_ready = false;
      media_pending = [];
      media_id = id;
      console.log("Loading " + cat[id].media);
      get_json(cat[id].data, function(data) {
        var title = data['Title'];
        console.log("Loaded data for " + id + ", " + title);
        $('#title').text(title);
        document.title = title;
        var chaps = data['chapters'];
        var cw = new ColourWheel(200, 60, 40, chaps.length);
        when_ready(function() {
          var player = $('#player')[0];
          var $chapters = $('#chapters');
          $chapters.empty()
          var sc = scaler(0, player.duration, 0, nav_width);
          for (var i = 0; i < chaps.length; i++) {
            build_chapter(sc, cw, chaps[i]);
          }
        });
      });
      $('#player').attr({
        src: cat[id].media
      });
      $('#nav').attr({
        src: cat[id].full
      });
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

  $('#player').bind('timeupdate', function(e) {
    $('#progress').width(Math.floor(this.currentTime / this.duration * nav_width));
  });

  $('#nav').click(function(e) {
    if (media_id) {
      var cx = (e.pageX - $(this).offset().left) / this.width;
      when_ready(function() {
        var player = $('#player')[0];
        player.currentTime = player.duration * cx;
      });
    }
  });

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
