function API(here) {
  this.base = here ? here : new URLParser(window.location.href);
  this.config_url = this.base.root() + '/config.json';
}

API.prototype = {
  _error: function(xhr, status, error) {
    //
  },
  _json: function(url, success) {
    $.ajax({
      url: url,
      context: this,
      dataType: 'json',
      global: false,
      success: success,
      error: this._error,
    });
  },
  setConfig: function(config) {


  },
  withConfig: function(cb) {
    if (this.config) {
      cb(this.config);
      return;
    }

    this._json(this.config_url, function(data) {
      this.setConfig(data);
      cb(this.config);
    });
  }
}
