$(function() {
  var here = new URLParser(window.location.href);
  var svc = here.makeAbsolute('svc/barcode.php');
  var cat = {};

  var media_id = null;
  var player_width = $('#player').width();
  console.log("width: ", player_width);
  var mp = new MagicPlayer('player', {
    width: player_width,
    height: 576
  });

  var sct = new Scaler(0, 10, 0, 10);

  function mk_id() {
    return Array.prototype.slice.call(arguments, 0).join('__');
  }

  function parse_id(id) {
    return id.split('__');
  }

  function getJson(url, cb) {
    $.ajax({
      url: url,
      context: this,
      dataType: 'json',
      global: false,
      success: cb
    });
  }

  function buildChapter(sc, cw, chap) {
    var left = sc.itrans(chap['in']);
    var right = sc.itrans(chap['out']);
    var col = cw.next();
    var id = mk_id('chapter', chap['in'], chap['out']);

    console.log("Chapter, left=", left, ", right=", right, ", col=", col);

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
      mp.getPlayer().seek(chap['in']);
    }));
  }

  function firstSentence(s) {
    var dot = s.indexOf('.');
    if (dot >= 0) return s.substr(0, dot);
    return s;
  }

  function loadChapters(id) {
    console.log("Loading " + cat[id].media);
    var $chapters = $('#chapters');
    $chapters.empty()
    getJson(cat[id].data, function(data) {
      var title = firstSentence(data['Title']);

      $('#title').text(title);
      document.title = title;

      console.log("Loaded data for " + id + ", " + title);

      var chaps = data['chapters'];
      mp.after('onTime', function(e) {
        console.log("Building chapters");
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

  function switchMedia(id, xp, yp) {
    console.log("switchMedia(\"" + id + "\", " + xp + ", " + yp + ")");
    if (id != media_id) {
      media_id = id;
      console.log("Loading " + cat[id].media);
      mp.load({
        file: cat[id].media,
        seekScaled: xp,
        onInit: function(player) {
          player.onTime(function(e) {
            $('#progress').width(Math.floor(e.position / e.duration * player_width));
          });
        }
      });
      $('#nav').attr({
        src: cat[id].full
      });
      loadChapters(id);
    }
    else {
      mp.seekScaled(xp);
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
        src: data[i].thumb
      })));
    }

    $('#nav').click(function(e) {
      var cx = (e.pageX - $(this).offset().left) / this.width;
      mp.seekScaled(cx);
    });

    $('#dock img').click(function(e) {
      var $this = $(this);
      var id = parse_id($this.attr('id')).shift();
      var offset = $this.offset();
      var cx = e.pageX - offset.left;
      var cy = e.pageY - offset.top;
      switchMedia(id, cx / this.width, cy / this.height);
    });

  });
});
