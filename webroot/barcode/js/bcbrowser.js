$(function() {
  var here = new URLParser(window.location.href);
  //  var svc = here.makeAbsolute('svc/barcode.php');
  var svc = 'http://newstream.hexten.net/barcode/svc/barcode.php';
  var cat = {};

  var media_id = null;
  var player_width = $('#player').width();
  var mp = new MagicPlayer('player', {
    width: player_width,
    height: 576
  });

  function getField(rec, name) {
    return rec['base'] + rec[name];
  }

  function mk_id() {
    return Array.prototype.slice.call(arguments, 0).join('__');
  }

  function parse_id(id) {
    return id.split('__');
  }

  function parseTime(tm) {
    var part = tm.split(':');
    var sec = 0;
    for (var i = 0; i < part.length; i++) sec = sec * 60 + (1 * part[i]);
    return sec;
  }

  function getJson(url, cb) {
    $.ajax({
      url: url,
      context: this,
      dataType: 'jsonp',
      global: false,
      success: cb
    });
  }

  function buildChapter(sc, cw, chap) {
    var left = sc.itrans(chap['in']);
    var right = sc.itrans(chap['out']);
    var col = cw.next();
    var id = mk_id('chapter', chap['in'], chap['out']);

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
      mp.seek(chap['in']);
    }));
  }

  function firstSentence(s) {
    var dot = s.indexOf('.');
    if (dot >= 0) return s.substr(0, dot);
    return s;
  }

  function loadChapters(id) {
    console.log("Loading " + getField(cat[id], 'media'));
    var $chapters = $('#chapters');
    $chapters.empty()
    getJson(cat[id].data, function(data) {
      var title = firstSentence(data['Title']);

      $('#title').text(title);
      document.title = title;

      console.log("Loaded data for " + id + ", " + title);

      var chaps = data['chapters'];
      mp.after('onTime', function(e) {
        var player = mp.getPlayer();
        $chapters.empty()
        var sc = new Scaler(0, mp.getDuration(), 0, $chapters.width());
        var cw = new ColourWheel(200, 60, 40, chaps.length);
        for (var i = 0; i < chaps.length; i++) {
          buildChapter(sc, cw, chaps[i]);
        }
      });
    });
  }

  function formatTime(n) {
    var part = [];
    n = Math.floor(n);
    do {
      var p = n % 60;
      n = Math.floor(n / 60);
      if (p < 10) p = '0' + p;
      part.unshift(p);
    } while (n > 0.1);
    return part.join(':');
  }

  function makeFrag(id, pos) {
    return[id, formatTime(pos)].join('.');
  }

  function switchMedia(id, seek) {
    console.log("switchMedia(\"" + id + "\", ", seek, ")");
    if (id != media_id) {
      media_id = id;
      console.log("Loading " + getField(cat[id], 'media'));
      mp.load({
        file: getField(cat[id], 'media'),
        seek: seek,
        onInit: function(player) {
          player.onTime(function(e) {
            $('#progress').width(Math.floor(e.position / e.duration * player_width));
            window.location.hash = makeFrag(media_id, e.position);
          });
        }
      });
      $('#nav').attr({
        src: getField(cat[id], 'full')
      });
      loadChapters(id);
    }
    else {
      mp.seek(seek);
    }
  }

  getJson(svc, function(data) {
    var dock = $('#dock');
    for (var i = 0; i < data.length; i++) {
      var name = data[i].name;
      cat[name] = data[i];
      var id = mk_id(name, 'thumb');
      dock.append($('<div></div>').attr({
        class: "wrap"
      }).append($('<img></img>').attr({
        id: id,
        src: getField(data[i], 'thumb')
      })));
    }

    $('#nav').click(function(e) {
      var cx = (e.pageX - $(this).offset().left) / this.width;
      mp.seek([cx]);
    });

    $('#dock img').click(function(e) {
      var $this = $(this);
      var id = parse_id($this.attr('id')).shift();
      var offset = $this.offset();
      var cx = e.pageX - offset.left;
      var cy = e.pageY - offset.top;
      switchMedia(id, [cx / this.width]);
    });

    if (here.parts.frag) {
      var fp = here.parts.frag.split('.');
      var id = fp.shift();
      var seek = fp.length ? parseTime(fp.shift()) : 0;
      switchMedia(id, seek);
    }
  });

});
