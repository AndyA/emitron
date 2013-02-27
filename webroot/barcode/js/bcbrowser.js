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
    var left = Math.floor(sc(chap['in']));
    var right = Math.floor(sc(chap['out']));
    var col = cw.next();
    var id = mk_id('chapter', chap['in'], chap['out']);

    console.log("Chapter: in=" + chap['in'] + ", out=" + chap['out'] + //
    ", left=" + left + ", right=" + right);

    $('#chapters').append($('<div></div>').attr({
      class: 'chapter',
      id: id
    }).css({
      left: left + 'px',
      width: (right - left) + 'px',
      backgroundColor: col
    }).mouseenter(function(e) {
      $('#popup').show().text(chap['desc']).css({
        borderColor: col
      }).position({
        my: 'bottom',
        at: 'top',
        of: '#' + id,
        collision: 'fit'
      });
    }).mouseleave(function(e) {
      $('#popup').hide();
    }).click(function(e) {
      jwplayer('player').seek(chap['in']);
    }));
  }

  var player = null;
  function load_media(url) {
    if (player) {
      player.load({
        file: url,
        autostart: true
      });
    } else {
      player = jwplayer('player').setup({
        file: url,
        width: 1024,
        height: 576,
        autostart: true
      }).onPlay(function(e) {
        console.log("Got some metadata");
        media_ready = true;
        for (var i = 0; i < media_pending.length; i++) {
          (media_pending[i])()
        }
        media_pending = [];
      }).onTime(function(e) {
        //    console.log("onTime, duration=" + e.duration + ", position=" + e.position);
        $('#progress').width(Math.floor(this.getPosition() / this.getDuration() * nav_width));
      });
    }
  }

  function switch_media(id, xp, yp) {
    console.log("switch_media(\"" + id + "\", " + xp + ", " + yp + ")");
    if (id != media_id) {
      media_ready = false;
      media_pending = [];
      media_id = id;
      console.log("Loading " + cat[id].media);
      load_media(cat[id].media);
      $('#nav').attr({
        src: cat[id].full
      });
      get_json(cat[id].data, function(data) {
        var title = data['Title'];
        console.log("Loaded data for " + id + ", " + title);
        $('#title').text(title);
        document.title = title;
        var chaps = data['chapters'];
        var cw = new ColourWheel(200, 60, 40, chaps.length);
        when_ready(function() {
          console.log("Showing chapters");
          var player = jwplayer('player');
          var $chapters = $('#chapters');
          $chapters.empty()
          var sc = scaler(0, player.getDuration(), 0, nav_width);
          for (var i = 0; i < chaps.length; i++) {
            build_chapter(sc, cw, chaps[i]);
          }
        });
      });
    }
    when_ready(function() {
      var player = jwplayer('player');
      player.seek(player.getDuration() * xp);
    });
  }

  //  var ev = [ //
  //  'onBeforePlay', 'onBuffer', 'onBufferChange', 'onBufferFull', 'onComplete', //
  //  'onError', 'onFullscreen', 'onIdle', 'onMeta', 'onMute', 'onPause', //'onPlay',
  //  'onPlaylist', 'onPlaylistItem', 'onReady', 'onResize', 'onSeek',
  //  /*'onTime',*/
  //  'onVolume'];
  //  function hook_event(p, ev) {
  //    p[ev](function(e) {
  //      console.log(ev);
  //    });
  //  }
  //  var player = jwplayer('player');
  //  for (var i = 0; i < ev.length; i++) hook_event(player, ev[i]);
  $('#nav').click(function(e) {
    if (media_id) {
      var cx = (e.pageX - $(this).offset().left) / this.width;
      when_ready(function() {
        var player = jwplayer('player');
        player.seek(player.getDuration() * cx);
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
