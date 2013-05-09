function Scaler(ilo, ihi, olo, ohi) {
  function scaler(ilo, ihi, olo, ohi) {
    return function(n) {
      n = ilo < ihi ? Math.max(ilo, Math.min(n, ihi)) : Math.max(ihi, Math.min(n, ilo));
      return (n - ilo) * (ohi - olo) / (ihi - ilo) + olo;
    };
  }
  this.trans = scaler(ilo, ihi, olo, ohi);
  this.inv = scaler(olo, ohi, ilo, ihi);
}

Scaler.prototype = {
  itrans: function(n) {
    return Math.floor(this.trans(n));
  },
  iinv: function(n) {
    return Math.floor(this.inv(n));
  }
}
