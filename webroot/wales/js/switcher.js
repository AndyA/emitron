$(function() {

  var SKIP_THUMB = 3;

  function mkid() {
    return Array.prototype.slice.call(arguments, 0).join('__');
  }

  function padNumber(n, digits) {
    var s = Math.floor(n).toString(10);
    while (s.length < digits) s = "0" + s;
    return s;
  }

  function thumbName(base, idx) {
    return base + '/' + padNumber(idx + SKIP_THUMB + 1, 5) + '.jpg';
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

  function loadThumbs(rec) {
    for (var i = 0; i < rec.thumbs.number; i++) {
      (function(img) {
        img.src = thumbName(rec.thumbs.base, i);
        img.onload = function(e) {
          console.log("Loaded ", img.src);
        }
      })(new Image());
    }
  }

  function switchMedia(id, seek) {
    console.log("switchMedia(\"" + id + "\", ", seek, ")");
    if (id != media_id) {
      media_id = id;
      //      console.log("Loading " + getField(cat[id], 'media'));
      $('#title').text(cat[id].title + ' (' + cat[id].tx_date + ')');
      mp.load({
        file: cat[id].media.a,
        seek: seek,
        onInit: function(player) {
          player.onTime(function(e) {
            $('#progress').width(Math.floor(e.position / e.duration * player_width));
            //            window.location.hash = makeFrag(media_id, e.position);
          });
        }
      });
      loadThumbs(cat[id]);
      $('#nav').attr({
        src: cat[id].thumbs.base + '/barcode.jpeg'
      });
      //      loadChapters(id);
    }
    else {
      mp.seek(seek);
    }
  }

  var here = new URLParser(window.location.href);
  var cat = {};

  var media_id = null;

  var $player = $('#player');
  var player_width = $player.width();
  var player_height = $player.height();

  var mp = new MagicPlayer('player', {
    width: player_width,
    height: player_height
  });

  getJson('index.json', function(data) {
    console.log('data: ', data);
    var dock = $('#dock');
    for (var i = 0; i < data.length; i++) {
      (function(d) {
        var name = d.name;
        cat[name] = d;
        console.log(name);
        dock.append($('<div class="wrap"></div>').append($('<a></a>').attr({
          href: '#'
        }).append($('<img></img>').attr({
          src: thumbName(d.thumbs.base, d.thumbs.number / 4),
          width: 192,
          height: 108
        })).append($('<div></div>').attr({
          class: "over"
        }).append($('<h1></h1>').text(d.title)).append($('<h2></h2>').text(d.tx_date))).click(function(e) {
          switchMedia(name, 0);
        })));
      })(data[i]);
    }

    $('#nav').click(function(e) {
      if (media_id) {
        var cx = (e.pageX - $(this).offset().left) / this.width;
        var thb = cat[media_id].thumbs.number - SKIP_THUMB;
        // quantise
        cx = Math.floor(cx * thb) / thb;
        mp.seek([cx]);
      }
    }).mousemove(function(e) {
      if (media_id) {
        var cx = (e.pageX - $(this).offset().left) / this.width;
        var thb = cat[media_id].thumbs;
        $('#popup img').attr({
          src: thumbName(thb.base, (thb.number - SKIP_THUMB) * cx)
        });
      }
      $('#popup').show().position({
        my: 'bottom-10',
        at: 'top',
        of: '#nav',
        using: function(pos, info) {
          info.element.element.css({
            left: Math.floor(e.clientX - info.element.width / 2) + 'px',
            top: pos.top + 'px'
          });
        }
      });
    }).mouseleave(function(e) {
      $('#popup').hide();
    });

  });

});
