window.$ = {
  find: function(selector, where) {
    if (!selector) {
      throw new Error('$.find: no selector given');
    }

    var collection = (where || document).querySelectorAll(selector);
    return Array.prototype.slice.apply(collection);
  },

  findOne: function(selector, where) {
    if (!selector) {
      throw new Error('$.findOne: no selector given');
    }

    return (where || document).querySelector(selector);
  },

  ajax: function(options) {
    var request = new XMLHttpRequest();
    request.open(options.method || 'GET', options.url, true);
    request.setRequestHeader('X-Requested-With', 'XMLHTTPRequest');

    request.onload = function() {
      if (this.status >= 200 && this.status < 400) {
        if (typeof options.success === 'function') {
          options.success(this.response);
        }
      } else {
        if (typeof options.error === 'function') {
          options.error();
        }
      }
    };

    request.onerror = function() {
      if (typeof options.error === 'function') {
        options.error();
      }
    };

    request.send();
  },

  log: function(text) {
    if (console.log) {
      console.log(text);
    }
  },

  formatPercent: function(value) {
    var int = Math.floor(value);
    var rest = value - int;
    return int + '.' + (rest > 0 ? rest.toString().substr(2, 1) : '0') + '%';
  },

  parentSection: function(start) {
    if (!start) {
      throw new Error('$.parentSection: no element given');
    }

    var element = start;

    while (element && element.tagName !== 'SECTION') {
      element = element.parentElement;
    }

    return element;
  }
};
