function scale(w, h, ar) {
  var hh = Math.floor(w / ar);
  return hh <= h ? [w, hh] : [Math.floor(h * ar), h];
}

$(function() {
  var ww = $(window).width();
  var wh = $(window).height();
  var sz = scale(ww, wh, 16 / 9);

  jwplayer('video').setup({
    file: '/live/roh-hls/dw-titles/dw-titles.m3u8',
    width: sz[0],
    height: sz[1]
  });

  jwplayer('video').onReady(function() {
    $('#video').offset({
      left: (ww - sz[0]) / 2,
      top: (wh - sz[1]) / 2
    });
    jwplayer('video').play();
  });

});
