(function() {
  var BasicCollection, GroupsMixin, IndexedCollection, _,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  _ = require('lodash');

  BasicCollection = require('./basic-collection');

  GroupsMixin = require('./groups-mixin');

  IndexedCollection = (function(superClass) {
    extend(IndexedCollection, superClass);

    IndexedCollection.include(GroupsMixin);

    function IndexedCollection(cfg) {
      var ref, ref1;
      this.primaryIndex = (ref = cfg.primaryIndex) != null ? ref : 'id';
      this.columnIndexes = (ref1 = cfg.columnIndexes) != null ? ref1 : [];
      IndexedCollection.__super__.constructor.call(this, cfg);
    }

    IndexedCollection.prototype._new = function(dataList) {
      return new IndexedCollection({
        primaryIndex: this.primaryIndex,
        columnIndexes: this.columnIndexes,
        data: dataList,
        groups: this._groups,
        autoGroups: this._autoGroups
      });
    };

    IndexedCollection.prototype.init = function(cfg) {
      var func, group, i, index, item, j, key, l, len, len1, len2, ref, ref1, ref2, ref3, ref4, ref5;
      IndexedCollection.__super__.init.call(this, cfg);
      this.indexes = {};
      this._groups = (ref = cfg.groups) != null ? ref : {};
      this.setAutoGroups(cfg.autoGroups);
      ref2 = (ref1 = cfg.autoGroups) != null ? ref1 : {};
      for (group in ref2) {
        func = ref2[group];
        if (typeof func === 'function') {
          this._autoGroups[group] = func;
        }
      }
      ref3 = this.columnIndexes;
      for (i = 0, len = ref3.length; i < len; i++) {
        index = ref3[i];
        this.indexes[index] = {};
      }
      if (!Array.isArray(cfg.data)) {
        return;
      }
      ref4 = cfg.data;
      for (j = 0, len1 = ref4.length; j < len1; j++) {
        item = ref4[j];
        if (this.primaryIndex in item) {
          this.set(item[this.primaryIndex], item);
        }
      }
      ref5 = this._keys;
      for (l = 0, len2 = ref5.length; l < len2; l++) {
        key = ref5[l];
        this._updateIndexes(key, this.map[key]);
      }
      return this;
    };

    IndexedCollection.prototype._updateIndexes = function(key, value) {
      var i, index, len, ref;
      ref = this.columnIndexes;
      for (i = 0, len = ref.length; i < len; i++) {
        index = ref[i];
        if (index in value) {
          this.indexes[index][value[index]] = key;
        }
      }
      return null;
    };

    IndexedCollection.prototype._onUpdate = function(key, value) {
      IndexedCollection.__super__._onUpdate.call(this, key, value);
      this._updateIndexes(key, value);
      return this._updateAutoGroups(key, value);
    };

    IndexedCollection.prototype._onDelete = function(key) {
      var i, index, keyToDelete, len, ref;
      IndexedCollection.__super__._onDelete.call(this, key);
      ref = this.columnIndexes;
      for (i = 0, len = ref.length; i < len; i++) {
        index = ref[i];
        keyToDelete = _.findKey(this.indexes[index], key);
        if (keyToDelete) {
          delete this.indexes[index][keyToDelete];
        }
      }
      return null;
    };

    IndexedCollection.prototype.getByIndex = function(index, indexKey) {
      return this.map[this.indexes[index][indexKey]];
    };

    IndexedCollection.prototype.sort = function(fields, orders) {
      var field;
      if (orders == null) {
        orders = {};
      }
      if (!Array.isArray(orders)) {
        orders = (function() {
          var i, len, results;
          results = [];
          for (i = 0, len = fields.length; i < len; i++) {
            field = fields[i];
            switch (orders[field]) {
              case 'ASC':
              case 'asc':
                results.push(true);
                break;
              case 'DESC':
              case 'desc':
                results.push(false);
                break;
              case null:
              case void 0:
                results.push(true);
                break;
              default:
                results.push(!!orders[field]);
            }
          }
          return results;
        })();
      }
      return this._new(_.sortByOrder(this.map, fields, orders));
    };

    IndexedCollection.prototype._filterFunctions = {
      startsWith: function(value, searchExpression) {
        return _.startsWith(value.toString().toLowerCase(), searchExpression);
      },
      has: function(value, searchExpression) {
        return value.toString().toLowerCase().indexOf(searchExpression) >= 0;
      },
      isTrue: function(value) {
        return !!value;
      },
      isFalse: function(value) {
        return !value;
      },
      equals: function(value, searchExpression) {
        return value === searchExpression;
      },
      exists: function() {
        return true;
      }
    };


    /*
    		Example filters:
    		1. [{ field: "ASIN", filters:{ startsWith: 'B4'} }]
    		2. [
    				{ field: "title", filters:{ has: 'ghost'} },
    				{ field: "Quantity", filters:{ equals: '0'} },
    			]
    		3. [
    				{ field: "title", filters:{ has: 'buster'} },
    				'or',
    				{ field: "title", filters:{ startsWith: 'ghost'} },
    			]
     */

    IndexedCollection.prototype.filter = function(filters) {
      var currentList, execFilterList, f, filtered, i, len, orList;
      if (filters == null) {
        filters = [];
      }
      execFilterList = (function(_this) {
        return function(filterList, value) {
          var expression, filter, func, funcName, i, len, ref, result;
          for (i = 0, len = filterList.length; i < len; i++) {
            filter = filterList[i];
            if (!(filter.field in value)) {
              return false;
            }
            ref = filter.filters;
            for (funcName in ref) {
              expression = ref[funcName];
              func = _this._filterFunctions[funcName];
              if (!func) {
                continue;
              }
              result = func(value[filter.field], expression);
              if (!result) {
                return false;
              }
            }
          }
          return true;
        };
      })(this);
      orList = [];
      currentList = [];
      for (i = 0, len = filters.length; i < len; i++) {
        f = filters[i];
        if (typeof f === 'string' && f.toLowerCase() === 'or') {
          if (currentList.length > 0) {
            orList.push(currentList);
          }
          currentList = [];
        } else {
          currentList.push(f);
        }
      }
      if (currentList.length > 0) {
        orList.push(currentList);
      }
      filtered = [];
      this.forEach(function(v, k) {
        var filterList, j, len1;
        for (j = 0, len1 = orList.length; j < len1; j++) {
          filterList = orList[j];
          if (execFilterList(filterList, v)) {
            filtered.push(v);
            break;
          }
        }
        return null;
      });
      return this._new(filtered);
    };

    return IndexedCollection;

  })(BasicCollection);

  module.exports = IndexedCollection;

}).call(this);
