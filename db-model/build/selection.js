(function() {
  var BasicCollection, Selection, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  _ = require('lodash');

  BasicCollection = require('./basic-collection');

  Selection = (function(superClass) {
    extend(Selection, superClass);

    function Selection(cfg) {
      Selection.__super__.constructor.call(this, cfg);
    }

    Selection.prototype.getSelected = function() {
      var k, ref, results, v;
      ref = this.map;
      results = [];
      for (k in ref) {
        v = ref[k];
        if (v === true) {
          results.push(k);
        }
      }
      return results;
    };

    return Selection;

  })(BasicCollection);

  module.exports = Selection;

}).call(this);
