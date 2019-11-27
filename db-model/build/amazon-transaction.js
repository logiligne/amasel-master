(function() {
  var AmazonTransaction, BasicCollection, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  _ = require('lodash');

  BasicCollection = require('./basic-collection');

  AmazonTransaction = (function(superClass) {
    extend(AmazonTransaction, superClass);

    function AmazonTransaction(cfg) {
      AmazonTransaction.__super__.constructor.call(this, cfg);
    }

    return AmazonTransaction;

  })(BasicCollection);

  module.exports = AmazonTransaction;

}).call(this);
