"use strict";



define(
	'dbModel'
	, [
	'jquery',
	'couchr',
	]
	, function (jquery,couchr) {
			var $ = jquery;

			var model = {};
			model.orders = [];
			model.orders_by_id = {};
			model.products = [];
			model.skus_by_asin = {};
			model.products_by_sku = {};
			model.purchaseOrders = [];
			model.loading={};
			model.cacheData=false;
			model.products_info_columns = [
				'ASIN', 'MarketplaceId', 'feature'	,
				'imageBig', 'imageSmall','lang' ,'title'];
			model.selfUrl =
				window.location.protocol + '//'
				+
				window.location.host + window.location.pathname;

				if(model.selfUrl[model.selfUrl.length-1] != '/'){
					model.selfUrl += '/';
				}

			model.setInProgress = function(v){
				if (model.inProgressSetter){
					model.inProgressSetter(v);
				}
			}

			model.startLoading = function(tag,scope) {
				model.loading[tag] = (model.loading[tag] || 0) +1;
				scope.nav.loadInProgress = true;
				console.log("start ", tag)
				return true;
			}

			model.doneLoading = function(tag,scope,cb) {
				model.loading[tag]--;
				if(model.loading[tag] == 0 && cb){
					cb(true);
				}
				console.log("done ", tag);
				for(var t in model.loading){
					if (model.loading[t]>0){
						return false;
					}
				}
				console.log("all done ", tag);
				if(cb){
					cb(false);
				}
				dataToModel(scope);
				return true;
			}

			var fetchFail = function(scope){
				console.log("fetchFail");
				scope.nav.loadInProgress = false;
			}

			var dataToModel = function(scope){
				scope.$apply(function(){
					if(scope.setOrders){
						scope.setOrders( model.orders );
					}
					if(scope.setProductsBySKU){
						scope.setProductsBySKU(model.products_by_sku);
					}
					if(scope.setProducts){
						scope.setProducts(model.products);
					}
					if(scope.setPurchaseOrders){
						scope.setPurchaseOrders(model.purchaseOrders);
					}
					if(scope.setBillingReports){
						scope.setBillingReports(model.billingReports);
					}
					if(scope.setRepricerHistory){
						scope.setRepricerHistory(model.repricerHistory);
					}
					console.log("datatomodel");
					scope.nav.loadInProgress = false;
				});
			}

			model.fetchOrders = function(scope){
				model.startLoading('orders',scope);
				var onfail = function(jqXHR, textStatus, errorThrown){
					fetchFail(scope);
					console.log( "Failed to fetch order items :", textStatus);
				};

				console.log("Start fetching orders.");
				$.ajax({
					url: model.selfUrl + 'api/_design/app/_view/unshipped_orders?include_docs=true',
				  dataType: "json",
					ifModified: true,
				}).done(function(data,textStatus, jqXHR){
					var orderIds = [];
					if(textStatus == 'notmodified'){
						for(var i in model.orders){
							var doc = model.orders[i];
							orderIds.push ( doc.AmazonOrderId );
						}
					}else{
						model.orders = [];
						for(var i in data.rows){
							var doc = data.rows[i].doc;
							model.orders.push( doc );
							model.orders_by_id[doc.AmazonOrderId] = doc;
							orderIds.push ( doc.AmazonOrderId );
						}
					}

					// Fetch orders items here
					model.startLoading('orders',scope);
					var postData = JSON.stringify({ keys: orderIds });
					$.ajax({
					  type: "POST",
					  url: model.selfUrl + 'api/_design/app/_view/orders_items_by_order_id?include_docs=true',
						contentType: 'application/json',
					  data: postData,
					  dataType: "json",
						ifModified: true,
					}).done(function(data,textStatus, jqXHR){
						if(textStatus != 'notmodified'){
							var seen = {};
							for(var i in data.rows){
								var doc = data.rows[i].doc;
								var order = model.orders_by_id[doc.AmazonOrderId];
								if( !seen[doc.AmazonOrderId] ) {
									order.items = [];
									seen[doc.AmazonOrderId] = true;
								}
								order.items.push( doc );
							}
						}
						model.doneLoading('orders',scope);
						console.log("Done fetching orders.");
					}).fail(onfail);

					// Fetch order flags
					model.startLoading('orders',scope);
					$.ajax({
					  type: "POST",
					  url: model.selfUrl + 'api/_design/app/_view/orders_flags?include_docs=true',
						contentType: 'application/json',
					  data: postData,
					  dataType: "json",
						ifModified: true,
					}).done(function(data,textStatus, jqXHR){
						if(textStatus != 'notmodified'){
							var seen = {};
							for(var i in data.rows){
								var doc = data.rows[i].doc;
								var order = model.orders_by_id[doc.AmazonOrderId];
								if( !seen[doc.AmazonOrderId] ) {
									order.flags = [];
									seen[doc.AmazonOrderId] = true;
								}
								if(doc.flags instanceof Array){
									order.flags = order.flags.concat( doc.flags );
								} else {
									order.flags.push( flags );
								}
							}
						}
						model.doneLoading('orders',scope);
						console.log("Done fetching orders.");
					}).fail(onfail);
					//
					model.doneLoading('orders',scope);
				}).fail(onfail);
			}

			model.fetchBillingreports = function(scope){
				model.startLoading('billingReports',scope);
				var onfail = function(jqXHR, textStatus, errorThrown){
					fetchFail(scope);
					console.log( "Failed to fetch billing reports :", textStatus);
				};

				$.ajax({
					url: model.selfUrl + 'api/_design/app/_view/billing_reports?include_docs=true',
				  dataType: "json",
					ifModified: true,
				}).done(function(data,textStatus, jqXHR){
					if(textStatus == 'notmodified'){
						// do nothing
					}else{
						model.billingReports = [];
						for(var i in data.rows){
							var doc = data.rows[i].doc;
							model.billingReports.push( doc );
						}
					}

					model.doneLoading('billingReports',scope);
				}).fail(onfail);
			}

			model.mergeProductInfo = function(){
				for(var i in model._productInfo){
					var doc = model._productInfo[i].doc;
					var productSKU = model.skus_by_asin[doc.ASIN];
					var product = model.products_by_sku[productSKU];
					for(var i in model.products_info_columns){
						var c = model.products_info_columns[i];
						product[c] = doc[c];
					}
				}
				model._productInfo = null;
			}

			model.mergeRepricerConfig = function() {
				for(var i in model._repricerConfig){
					var doc = model._repricerConfig[i].doc;
					var product = model.products_by_sku[doc.SKU];
					if (product) {
						product.repricer = doc.config;
					}
					//console.log("mrc", product);
				}
				model._repricerConfig = null;
			}

			model.fetchProducts = function(scope, options){
				var onfail = function(jqXHR, textStatus, errorThrown){
					fetchFail(scope);
					console.log( "Failed to fetch products :", textStatus);
				};

				if(!options) {
					options = {}
				}

				var finalMerge = function (done) {
					if(done){
						//console.log("Final merge...");
						model.mergeProductInfo();
						model.mergeRepricerConfig();
					}
				}

				console.log("Start fetching inventory.");
				model.startLoading('products',scope);
				$.ajax({
					url: model.selfUrl + 'api/_design/app/_view/products?include_docs=true',
				  dataType: "json",
					ifModified: true
				}).done(function(data,textStatus, jqXHR){
					if(textStatus != 'notmodified'){
						model.products = [];
						for(var i in data.rows){
							var doc = data.rows[i].doc;
							model.products.push( doc );
							model.skus_by_asin[doc.ASIN] = doc.SKU;
							model.products_by_sku[doc.SKU] = doc;
						}
					}
					model.doneLoading('products',scope,finalMerge);
					console.log("Done fetching inventory.");
				}).fail(onfail);

				console.log("Start fetching product info.");
				model.startLoading('products',scope);
				$.ajax({
				  url: model.selfUrl + 'api/_design/app/_view/products_info?include_docs=true',
				  dataType: "json",
					ifModified: true
				}).done(function(data,textStatus, jqXHR){
					if(textStatus != 'notmodified'){
						model._productInfo = data.rows;
					}
					model.doneLoading('products',scope,finalMerge);
					console.log("Done fetching product info.");
				}).fail(onfail);

				if(options.withRepricerConfig) {
					console.log("Start fetching repricer config.");
					model.startLoading('products',scope);
					$.ajax({
						url: model.selfUrl + 'api/_design/app/_view/repricer_config?include_docs=true',
						dataType: "json",
						ifModified: true
					}).done(function(data,textStatus, jqXHR){
						if(textStatus != 'notmodified'){
							model._repricerConfig = data.rows;
						}
						model.doneLoading('products',scope,finalMerge);
						console.log("Done fetching repricer config.");
					}).fail(onfail);

				}
			}

			model.fetchPurchaseOrders = function(scope){
				model.startLoading('purchaseOrders',scope);
				var onfail = function(jqXHR, textStatus, errorThrown){
					fetchFail(scope);
					console.log( "Failed to fetch purchaseOrders :", textStatus);
				};

				console.log("Start fetching purchaseOrders.");
				$.ajax({
					url: model.selfUrl+ 'api/_design/app/_view/purchase_orders?include_docs=true',
				  dataType: "json",
					ifModified: true
				}).done(function(data,textStatus, jqXHR){
					if(textStatus != 'notmodified'){
						model.purchaseOrders = [];
						for(var i in data.rows){
							var doc = data.rows[i].doc;
							model.purchaseOrders.push( doc );
						}
					}
					model.doneLoading('purchaseOrders',scope);
					console.log("Done fetching purchaseOrders.");
				}).fail(onfail);
			}

			model.fetchRepricerHistory = function(scope, startDate, endDate){
				if(!startDate) {
					startDate = new Date();
					startDate.setDate( startDate.getDate() - 2);
					startDate = startDate.toISOString();
				}
				if(!endDate) {
					endDate = new Date().toISOString()
				}
				model.startLoading('repricerHistory',scope);
				var onfail = function(jqXHR, textStatus, errorThrown){
					fetchFail(scope);
					console.log( "Failed to fetch repricerHistory :", textStatus);
				};

				console.log("Start fetching repricerHistory.");
				$.ajax({
					url: model.selfUrl+ 'api/_design/app/_view/repricer_history?include_docs=true&descending=true&startkey="'+endDate+'"&endkey="'+startDate+'"',
				  dataType: "json",
					ifModified: true
				}).done(function(data,textStatus, jqXHR){
					if(textStatus != 'notmodified'){
						model.repricerHistory = [];
						for(var i in data.rows){
							var doc = data.rows[i].doc;
							model.repricerHistory.push({
								time : new Date(doc.startTime),
								deltaPrices: doc.deltaPrices,
								newPrices: doc.newPrices,
								skippedRepricing: doc.skippedRepricing
							});
						}
					}
					model.doneLoading('repricerHistory',scope);
					console.log("Done fetching repricerHistory.");
				}).fail(onfail);
			}


			model.saveFlags = function(orderIds, doneCb){
				if (!Array.isArray(orderIds)){
					orderIds = [ orderIds ];
				}
				model.setInProgress(true);
				var viewURL =model.selfUrl +
							'api/_design/app/_view/orders_flags?include_docs=true&keys=' +
							JSON.stringify(orderIds);
				couchr.get(viewURL, function(err, doc){
					if(err){
						console.log('Error while fetching current flags:', err);
						if(doneCb){
							doneCb(err, null);
						}
						return;
					}
					var docMap = {};
					for(var row of doc.rows){
						docMap[row.doc.AmazonOrderId] = row.doc;
					}
					var bulkDocs = [];
					for(var orderId of orderIds){
						var flags = model.orders_by_id[orderId].flags;
						var docId = 'order-flags-' + orderId;

						if(docMap[orderId]){
							// If we have preious docs flags
							if(!flags || flags.length ==0){
								// Delete if no current flags
								bulkDocs.push({
									_id: docId,
									_rev: docMap[orderId]._rev,
									_deleted : true,
								});
							} else {
								// update
								docMap[orderId].flags = flags
								bulkDocs.push(docMap[orderId]);
							}
						} else {
							// no previous flags
							if(flags && flags.length > 0){
								// create new doc
								bulkDocs.push({
									_id: docId,
									'AmazonOrderId' : orderId,
									'objType' : 'orderFlags',
									'flags' :  flags,
								});
							} else {
								// no op
							}
						}
					}
					bulkDocs = {docs: bulkDocs};
					console.log(bulkDocs);
					couchr.post(model.selfUrl + 'api/_bulk_docs', bulkDocs ,function(err, doc){
						if(err){
							alert('Error while saving flags:' + err);
						}
						model.setInProgress(false);
						if(doneCb){
							doneCb(null, true);
						}
					});
				});
				return;
				/*
				var orderId = orderIds[0];
				var docId = 'order-flags-' + orderId;
				var newDoc = {
					_id: docId,
					'AmazonOrderId' : orderId,
					'objType' : 'orderFlags',
					'flags' :  model.orders_by_id[orderId].flags,
				};
				couchr.get(model.selfUrl + 'api/'+docId, function (err, doc) {
					if(err == null){
						newDoc._rev = doc._rev;
					}
					if(!newDoc.flags || newDoc.flags.length ==0){
						couchr.del(model.selfUrl + 'api/'+docId+'?rev='+newDoc._rev, function (err, doc) {
							console.log("Deleted flags.");
							model.setInProgress(false);
						});
					} else {
						couchr.put(model.selfUrl + 'api/'+docId, newDoc ,function (err, doc) {
							console.log("Saved flags");
							model.setInProgress(false);
						});
					}
				});
				*/
			}

			model.saveRepriceConfig = function(sku, config,cb){
				var docId = 'reprice-config-' + encodeURIComponent(sku);
				if(!config.active){
					config.active = false;
				}
				if( typeof config.minPrice != "string" ){
				  config.minPrice = "" + config.minPrice ? config.minPrice : "";
				}
				if( typeof config.maxPrice != "string" ){
				  config.minPrice = "" + config.maxPrice ? config.maxPrice : "";
				}
				var newDoc = {
					_id: docId,
					'objType' : 'repricerConfig',
					'SKU' : sku,
					'config' :  config,
				};
				model.setInProgress(true);

				couchr.get(model.selfUrl + 'api/'+docId, function (err, doc) {
					if(err == null){
						newDoc._rev = doc._rev;
					}
					couchr.put(model.selfUrl + 'api/'+docId, newDoc ,function (err, doc) {
						console.log("Saved repriceConfig");
						model.setInProgress(false);
						if(cb){
							cb();
						}
					});
				});
			}

			model.savePurchaseOrder = function(sku,quantity,cb){
				var docId = 'puchase-order-' + encodeURIComponent(sku);
				if(typeof quantity == "undefined" || quantity == null) {
					quantity==25;
				}
				var newDoc = {
					_id: docId,
					'objType' : 'purchaseOrder',
					'SKU' : sku,
					'Quantity' :  quantity,
				};
				model.setInProgress(true);

				couchr.get(model.selfUrl + 'api/'+docId, function (err, doc) {
					if(err == null){
						newDoc._rev = doc._rev;
					}
					if(newDoc.Quantity ==0){
						couchr.del(model.selfUrl + 'api/'+docId+'?rev='+newDoc._rev, function (err, doc) {
							console.log("Deleted purchase order.");
							model.setInProgress(false);
							if(cb){
								cb();
							}
						});
					} else {
						couchr.put(model.selfUrl + 'api/'+docId, newDoc ,function (err, doc) {
							console.log("Saved purchase order");
							model.setInProgress(false);
							if(cb){
								cb();
							}
						});
					}
				});
			}
			model.deleteAllFromView = function(view, cb){
					couchr.get(model.selfUrl + 'api/_design/app/_view/' + view + '?include_docs=true', function (err, doc) {
						if(err != null){
							console.log("failed to get view: "+ view, err);
							return;
						}
						console.log(doc);
						model.setInProgress(true);
						if(doc.rows.length >= 1){
							var del = [];
							for(var i in doc.rows){
								del.push({
									_id : doc.rows[i].doc._id,
									_rev : doc.rows[i].doc._rev,
									_deleted : true,
								});
							}
							couchr.post(model.selfUrl + 'api/_bulk_docs',{docs: del}, function (err, doc) {
								console.log("Deleted " + doc.length + " docs from view : " + view);
								model.setInProgress(false);
								if(cb){
									cb();
								}
							});
						}else {
							model.setInProgress(false);
							console.log("View empty: "+ view);
						}
					});
			}

			return model;
	 }
);
