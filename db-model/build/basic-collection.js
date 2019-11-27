(function() {
  var BasicCollection, EventEmitter, _,
    slice = [].slice;

  _ = require('lodash');

  require('./mixin');

  EventEmitter = require('events').EventEmitter;

  BasicCollection = (function() {
    function BasicCollection(cfg) {
      this.init(cfg);
      this._events = {};
    }

    BasicCollection.prototype.init = function(cfg) {
      this.map = {};
      this._keys = [];
      return this;
    };

    BasicCollection.prototype.refEvents = function(tag) {
      if (tag == null) {
        tag = 'default';
      }
      if (!(tag in this._events)) {
        this._events[tag] = {
          ee: new EventEmitter(),
          refs: 0
        };
      }
      this._events[tag].refs++;
      return this._events[tag].ee;
    };

    BasicCollection.prototype.unrefEvents = function(tag) {
      if (tag == null) {
        tag = 'default';
      }
      if (!(tag in this._events)) {
        return;
      }
      this._events[tag].refs--;
      if (this._events[tag].refs === 0) {
        return delete this._events[tag];
      }
    };

    BasicCollection.prototype._emitEvent = function() {
      var args, event, k, ref, ref1, results, v;
      event = arguments[0], args = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      ref = this._events;
      results = [];
      for (k in ref) {
        v = ref[k];
        results.push((ref1 = v.ee).emit.apply(ref1, [event].concat(slice.call(args))));
      }
      return results;
    };

    BasicCollection.prototype._onUpdate = function(key, value) {
      return this._emitEvent('changed', key, value);
    };

    BasicCollection.prototype._onDelete = function(key) {
      return this._emitEvent('changed', key, null);
    };

    BasicCollection.prototype.forEach = function(cb) {
      var i, key, len, ref, results;
      if (cb != null) {
        ref = this._keys;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          key = ref[i];
          results.push(cb(this.map[key], key));
        }
        return results;
      }
    };

    BasicCollection.prototype.length = function() {
      return this._keys.length;
    };

    BasicCollection.prototype.keys = function() {
      return this._keys.slice(0);
    };

    BasicCollection.prototype.has = function(key) {
      return key in this.map;
    };

    BasicCollection.prototype.get = function(key) {
      return this.map[key];
    };

    BasicCollection.prototype.getAtPosition = function(idx) {
      if ((0 <= idx && idx < this._keys.length)) {
        return this.map[this._keys[idx]];
      } else {
        return null;
      }
    };

    BasicCollection.prototype.set = function(key, value) {
      if (!(key in this.map)) {
        this._keys.push(key);
      }
      this.map[key] = value;
      return this._onUpdate(key, value);
    };

    BasicCollection.prototype.update = function(key, value, customizer) {
      if (!(key in this.map) || (this.map[key] == null)) {
        return this.set(key, value);
      }
      _.assign(this.map[key], value, customizer);
      return this._onUpdate(key, value);
    };

    BasicCollection.prototype.merge = function(key, value, customizer) {
      if (!(key in this.map) || (this.map[key] == null)) {
        return this.set(key, value);
      }
      _.merge(this.map[key], value, customizer);
      return this._onUpdate(key, value);
    };

    BasicCollection.prototype["delete"] = function(key) {
      this._onDelete(key);
      if (!(key in this.map)) {
        return;
      }
      delete this.map[key];
      _.pull(this._keys, key);
      return null;
    };

    BasicCollection.prototype.asList = function() {
      var i, key, len, ref, results;
      ref = this._keys;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        key = ref[i];
        results.push(this.map[key]);
      }
      return results;
    };

    return BasicCollection;

  })();

  module.exports = BasicCollection;

}).call(this);
