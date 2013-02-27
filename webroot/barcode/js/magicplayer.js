function MagicPlayer(elt, defaults) {
  this.elt = elt
  this.defaults = defaults || {}
}

MagicPlayer.prototype = (function() {
  function callAll(self, list, args) {
    for (var i = 0; i < list.length; i++) list[i].apply(self, args)
  }
  function installHook(self, pl, name, args) {
    pl[name](function(e) {
      var detail = [name]
      for (var i = 0; i < args.length; i++) {
        detail.push(args[i] + '=' + e[args[i]])
      }
      console.log(detail.join(', '))

      if (!self.seen[name]) self.seen[name] = 0
      if ((!self.seen[name]++) && self.defer[name]) {
        callAll(self, self.defer[name], [])
        self.defer[name] = []
      }
    })
  }

  function installHooks(self) {
    var ev = {
      onBeforePlay: [],
      onBuffer: ['oldstate'],
      onBufferChange: ['bufferPercent'],
      onComplete: [],
      onError: ['message'],
      onFullscreen: ['fullscreen'],
      onIdle: ['oldstate'],
      onMeta: ['metadata'],
      onMute: ['mute'],
      onPause: ['oldstate'],
      onPlay: ['oldstate'],
      onPlaylist: ['playlist'],
      onPlaylistItem: [],
      onReady: [],
      onResize: ['width', 'height'],
      onSeek: ['position', 'offset'],
      onTime: ['duration', 'offset', 'position'],
      onVolume: ['volume']
    }
    $.each(ev, function(k, v) {
      installHook(self, self.player, k, v)
    })
  }

  function installExtra(self) {
    // For some reason JWP sometimes doesn't know the duration even
    // after reporting it in an onTime event. So we cache any positive
    // duration here. Seen with Firefox, may apply to others.
    self.player.onTime(function(e) {
      if (e.duration > self.duration) self.duration = e.duration;
    });
  }

  return {
    reset: function() {
      this.seen = {};
      this.defer = {};
      this.duration = -1;
    },
    after: function(ev, cb) {
      if (this.seen[ev]) {
        cb.apply(this);
      } else {
        if (!this.defer[ev]) this.defer[ev] = [];
        this.defer[ev].push(cb);
      }
    },
    load: function(opt) {
      this.reset()
      if (this.player) {
        this.player.load(opt)
      } else {
        this.player = jwplayer(this.elt).setup($.extend({},
        this.defaults, opt));
        installExtra(this); // do this first
        installHooks(this);
        if (opt.onInit) opt.onInit.apply(this, [this.player]);
      }
      if (opt.seekScaled) {
        this.player.play();
        this.after('onPlay', function(e) {
          this.after('onTime', function(e) {
            this.player.seek(this.player.getDuration() * opt.seekScaled);
          });
        });
      }
      else if (opt.seek) {
        this.player.play();
        this.after('onPlay', function(e) {
          this.player.seek(opt.seek);
        });
      }
      return this
    },
    seekScaled: function(n) {
      if (this.player) {
        this.after('onTime', function(e) {
          this.player.seek(this.player.getDuration() * n);
        });
      }
    },
    getPlayer: function() {
      return this.player;
    },
    getDuration: function() {
      return this.duration;
    }
  }
})()
