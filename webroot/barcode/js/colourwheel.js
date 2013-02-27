// http://goessner.net/articles/JsonPath/
function ColourWheel(h, s, l, n) {
  this.h = h;
  this.s = s;
  this.l = l;
  var per_colour = 360 / n;
  this.i = per_colour;
}

ColourWheel.prototype = (function() {
  // Private stuff here
  return {
    next: function() {
      var col = 'hsl(' + Math.floor(this.h) + ',' + this.s + '%,' + this.l + '%)';
      this.h += this.i;
      return col;
    }
  };
})();
