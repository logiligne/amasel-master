(function() {
  var DbModel, INSTANCES, IndexedCollection, PouchDB, _;

  PouchDB = require('pouchdb');

  _ = require('lodash');

  IndexedCollection = require('./indexed-collection');

  DbModel = (function() {
    DbModel.prototype.DESIGN_DOC = 'app';

    DbModel.prototype.PRODUCTS_COLUMNS = ["SKU", "ASIN", "Price", "Quantity"];

    DbModel.prototype.PRODUCTS_INFO_COLUMNS = ['ASIN', 'MarketplaceId', 'feature', 'imageBig', 'imageSmall', 'lang', 'title'];

    DbModel.prototype.ORDERS_COLUMNS = ["ShipmentServiceLevelCategory", "OrderTotal", "ShipServiceLevel", "LatestShipDate", "MarketplaceId", "SalesChannel", "ShippingAddress", "ShippedByAmazonTFM", "OrderType", "FulfillmentChannel", "BuyerEmail", "OrderStatus", "BuyerName", "LastUpdateDate", "EarliestShipDate", "PurchaseDate", "NumberOfItemsUnshipped", "NumberOfItemsShipped", "PaymentMethod", "AmazonOrderId"];

    DbModel.prototype.ORDER_ITEMS_COLUMNS = ["OrderItemId", "GiftWrapPrice", "QuantityOrdered", "GiftWrapTax", "SellerSKU", "Title", "ShippingTax", "ShippingPrice", "ItemTax", "ItemPrice", "PromotionDiscount", "ConditionId", "ASIN", "QuantityShipped", "ConditionSubtypeId", "ShippingDiscount", "AmazonOrderId"];

    DbModel.prototype.ORDER_FLAGS_COLUMNS = ["AmazonOrderId", "flags"];

    DbModel.prototype.PURCHASE_ORDERS_COLUMNS = ["Quantity", "SKU"];

    function DbModel(config) {
      this.db = new PouchDB(config);
      this._clear();
    }

    DbModel.prototype._clear = function() {
      this.unshippedOrders = new IndexedCollection("AmazonOrderId");
      this.products = new IndexedCollection("ASIN", ["SKU"]);
      this.purchaseOrders = new IndexedCollection("SKU");
      this.billingReports = [];
      return this.repricerHistory = new IndexedCollection("time");
    };

    DbModel.prototype._processResult = function(dataList) {
      var data, doc, flags, i, j, len, len1, ref, row, v;
      if (!Array.isArray(dataList)) {
        dataList = [dataList];
      }
      for (i = 0, len = dataList.length; i < len; i++) {
        data = dataList[i];
        ref = data.rows;
        for (j = 0, len1 = ref.length; j < len1; j++) {
          row = ref[j];
          doc = row.doc;
          if (doc.objType == null) {
            throw new Error('Unknown data object:' + JSON.stringify(row));
          }
          switch (doc.objType) {
            case "item":
              this.products.update(doc.ASIN, _.pick(doc, this.PRODUCTS_COLUMNS));
              break;
            case "itemInfo":
              this.products.update(doc.ASIN, _.pick(doc, this.PRODUCTS_INFO_COLUMNS));
              break;
            case "order":
              if (doc.OrderStatus === "Unshipped") {
                this.unshippedOrders.update(doc.AmazonOrderId, _.pick(doc, this.ORDERS_COLUMNS));
              } else {
                this.unshippedOrders["delete"](doc.AmazonOrderId);
              }
              break;
            case "orderItem":
              if (this.unshippedOrders.has(doc.AmazonOrderId)) {
                this.unshippedOrders.update(doc.AmazonOrderId, {
                  items: [_.pick(doc, this.ORDER_ITEMS_COLUMNS)]
                }, function(value, other) {
                  if (Array.isArray(value)) {
                    return value.concat(other);
                  } else {
                    return other;
                  }
                });
              }
              break;
            case "orderFlags":
              if (this.unshippedOrders.has(doc.AmazonOrderId)) {
                flags = Array.isArray(doc.flags) ? doc.flags : [doc.flags];
                this.unshippedOrders.update(doc.AmazonOrderId, {
                  flags: flags
                }, function(value, other) {
                  if (Array.isArray(value)) {
                    return value.concat(other);
                  } else {
                    return other;
                  }
                });
              }
              break;
            case "billing":
              if (doc.objSubtype === "billingReport") {
                this.billingReports.push(doc);
              }
              break;
            case "purchaseOrder":
              this.purchaseOrders.update(doc.SKU, _.pick(doc, this.PURCHASE_ORDERS_COLUMNS));
              break;
            case "syncOperation":
              if (doc.objSubtype === "price") {
                v = {
                  time: new Date(doc.startTime),
                  deltaPrices: doc.deltaPrices,
                  newPrices: doc.newPrices,
                  skippedRepricing: doc.skippedRepricing
                };
                this.repricerHistory.update(v.time, v);
              }
          }
        }
      }
      return dataList;
    };

    DbModel.prototype._fetchView = function(viewName, options) {
      if (options == null) {
        options = {};
      }
      if (options.reduce == null) {
        options.reduce = false;
      }
      if (options.include_docs == null) {
        options.include_docs = true;
      }
      return this.db.query(this.DESIGN_DOC + '/' + viewName, options).then((function(_this) {
        return function(result) {
          return _this._processResult(result);
        };
      })(this));
    };

    DbModel.prototype.fetch = function(dataTags, options) {
      var dataTag, dataTagList, fnName, i, len, promise;
      if (options == null) {
        options = {};
      }
      dataTagList = Array.isArray(dataTags) ? dataTag : [dataTags];
      if (dataTags.length === 0) {
        return new Promise(function(resolve, reject) {
          return reject(new Error('No data tag specified in fetch: ' + dataTag));
        });
      }
      for (i = 0, len = dataTags.length; i < len; i++) {
        dataTag = dataTags[i];
        fnName = 'fetch' + dataTag;
        if (typeof this[fnName] !== 'function') {
          return new Promise(function(resolve, reject) {
            return reject(new Error('Invalid data tag in fetch: ' + dataTag));
          });
        }
        if (promise) {
          promise = promise.then((function(_this) {
            return function(value) {
              return _this[fnName](options);
            };
          })(this));
        } else {
          promise = this[fnName](options);
        }
      }
      return promise;
    };

    DbModel.prototype.fetchUnshippedOrders = function(options) {
      if (options == null) {
        options = {};
      }
      return this._fetchView('unshippedOrders', options).then((function(_this) {
        return function(result) {
          var keys;
          keys = _this.unshippedOrders.keys();
          return Promise.all([
            _this._fetchView('orders_items_by_order_id', {
              keys: keys
            }), _this._fetchView('orders_flags', {
              keys: keys
            })
          ]).then(function() {
            return _this;
          });
        };
      })(this));
    };

    DbModel.prototype.fetchBillingReports = function(options) {
      if (options == null) {
        options = {};
      }
      return this._fetchView('billing_reports', options).then((function(_this) {
        return function(result) {
          return _this;
        };
      })(this));
    };

    DbModel.prototype.fetchProducts = function(options) {
      if (options == null) {
        options = {};
      }
      return Promise.all([this._fetchView('products'), this._fetchView('products_info')]).then((function(_this) {
        return function() {
          return _this;
        };
      })(this));
    };

    DbModel.prototype.fetchPurchaseOrders = function(options) {
      if (options == null) {
        options = {};
      }
      return this._fetchView('purchase_orders', options).then((function(_this) {
        return function(result) {
          return _this;
        };
      })(this));
    };

    DbModel.prototype.saveFlags = function(orderId, options) {
      var docId, newDoc;
      if (options == null) {
        options = {};
      }
      docId = 'order-flags-' + orderId;
      newDoc = {
        _id: docId,
        AmazonOrderId: orderId,
        objType: 'orderFlags',
        flags: model.unshippedOrders.get(orderId).flags
      };
      return db.get(docId).then(function(doc) {
        newDoc._rev = doc._rev;
        if (!newDoc.flags || newDoc.flags.length === 0) {
          return db.remove(docId, newDoc._rev);
        } else {
          return db.put(newDoc);
        }
      })["catch"](function(err) {
        if (err.status === 404 && reason === 'missing') {
          return db.put(newDoc);
        } else {
          throw err;
        }
      });
    };

    return DbModel;

  })();

  INSTANCES = {};

  module.exports = {
    DbModel: DbModel,
    get: function(config) {
      var key;
      key = JSON.stringify(config);
      if (key in INSTANCES) {
        return INSTANCES[key];
      }
      return INSTANCES[key] = new DbModel(config);
    }
  };

}).call(this);
