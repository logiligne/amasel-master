(function() {
  var GroupsMixin, _;

  _ = require('lodash');

  GroupsMixin = (function() {
    function GroupsMixin() {}

    GroupsMixin.prototype._groups = {};

    GroupsMixin.prototype._autoGroups = {};

    GroupsMixin.prototype._expandGroup = function(group) {
      var domain, groups;
      if (group.indexOf('*') === group.length - 1) {
        domain = group.slice(0, group.length - 1);
        groups = _.filter(Object.keys(this._groups), function(value) {
          return _.startsWith(value, domain);
        });
        return groups;
      } else {
        return [group];
      }
    };

    GroupsMixin.prototype.isInGroup = function(group, key) {
      var g, i, len, ref, ref1;
      ref = this._expandGroup(group);
      for (i = 0, len = ref.length; i < len; i++) {
        g = ref[i];
        if ((ref1 = this._groups[g]) != null ? ref1[key] : void 0) {
          return true;
        }
      }
      return false;
    };

    GroupsMixin.prototype.addToGroup = function(group, key) {
      var old;
      if (!(group in this._groups)) {
        this._groups[group] = {};
      }
      old = this._groups[group][key];
      this._groups[group][key] = true;
      if (!old) {
        this._emitEvent('groupsChanged');
      }
      return null;
    };

    GroupsMixin.prototype.removeFromGroup = function(group, key) {
      var g, i, len, ref, wasInGroup;
      wasInGroup = false;
      ref = this._expandGroup(group);
      for (i = 0, len = ref.length; i < len; i++) {
        g = ref[i];
        wasInGroup || (wasInGroup = this._groups[g][key]);
        delete this._groups[g][key];
      }
      if (wasInGroup) {
        this._emitEvent('groupsChanged');
      }
      return null;
    };

    GroupsMixin.prototype.clearGroup = function(group) {
      var g, i, len, ref;
      ref = this._expandGroup(group);
      for (i = 0, len = ref.length; i < len; i++) {
        g = ref[i];
        this._groups[g] = {};
      }
      this._emitEvent('groupsChanged');
      return null;
    };

    GroupsMixin.prototype.getKeysInGroup = function(group) {
      var g, key, retVal, value;
      if (group in this._groups) {
        g = this._groups[group];
      } else {
        g = {};
      }
      retVal = [];
      for (key in g) {
        value = g[key];
        if (this.has(key) && value === true) {
          retVal.push(key);
        }
      }
      return retVal;
    };

    GroupsMixin.prototype.getNumberOfKeysInGroup = function(group) {
      var g, key, retVal, value;
      if (group in this._groups) {
        g = this._groups[group];
      } else {
        return 0;
      }
      retVal = 0;
      for (key in g) {
        value = g[key];
        if (this.has(key) && value === true) {
          retVal++;
        }
      }
      return retVal;
    };

    GroupsMixin.prototype.getGroups = function(domain) {
      if (!domain) {
        return Object.keys(this._groups);
      }
      return _.map(this._expandGroup(domain), function(value) {
        return value.replace(domain, '');
      });
    };

    GroupsMixin.prototype.getAutoGroups = function() {
      return this._autoGroups;
    };

    GroupsMixin.prototype.setAutoGroups = function(autoGroups) {
      if (autoGroups == null) {
        autoGroups = {};
      }
      this._autoGroups = {};
      this.addAutoGroups(autoGroups);
      return null;
    };

    GroupsMixin.prototype.addAutoGroups = function(autoGroups) {
      var func, group;
      if (autoGroups == null) {
        autoGroups = {};
      }
      for (group in autoGroups) {
        func = autoGroups[group];
        if (typeof func === 'function') {
          this._autoGroups[group] = func;
        }
      }
      this.forEach((function(_this) {
        return function(value, key) {
          return _this._updateAutoGroups(key, value);
        };
      })(this));
      return null;
    };

    GroupsMixin.prototype._updateAutoGroups = function(key, value) {
      var changed, func, group, groups, i, isInGroup, j, len, len1, r, ref, result;
      changed = false;
      ref = this._autoGroups;
      for (group in ref) {
        func = ref[group];
        isInGroup = this.isInGroup(group, key);
        result = func(value, key);
        if (!Array.isArray(result)) {
          result = [result];
        }
        if (group.indexOf('*') === group.length - 1) {
          groups = this._expandGroup(group);
          this.removeFromGroup(group, key);
          for (i = 0, len = result.length; i < len; i++) {
            r = result[i];
            if ((typeof r === 'boolean') || (typeof r === 'number') || r) {
              group = group.replace('*', r.toString());
              this.addToGroup(group, key);
            }
          }
          changed || (changed = isInGroup && result.length === 0);
          changed || (changed = !isInGroup && result.length >= 0);
        } else {
          for (j = 0, len1 = result.length; j < len1; j++) {
            r = result[j];
            if (!!r && !isInGroup) {
              this.addToGroup(group, key);
              changed = true;
            }
            if (!r && isInGroup) {
              this.removeFromGroup(group, key);
              changed = true;
            }
          }
        }
      }
      if (changed) {
        this._emitEvent('groupsChanged');
      }
      return null;
    };

    GroupsMixin.prototype._dumpGroups = function() {
      var group, i, len, ref, results;
      ref = this.getGroups();
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        group = ref[i];
        results.push(console.log(group + " :", JSON.stringify(this._groups[group])));
      }
      return results;
    };

    return GroupsMixin;

  })();

  module.exports = GroupsMixin;

}).call(this);
