"use strict";

define(
	'appConfig'
	, [
	'underscore',
	'couchr',
	'print/dimUnit',
	'cfg/default_print_template'
	]
	, function (_, couchr, dimUnit, printTemplate) {
			var dbUrl =
				window.location.protocol + '//' +
				window.location.host + window.location.pathname +
				'api/'
				;

			// Set config defaults
			var cfg = {
				_initialized : false,
				_defaults: {
					units : {
						default: 'mm',
						allowed: [ 'cm', 'mm', 'in' ],
					},
					printSettings: {
            "Envelope 179x114": {
               "comment": "Envelope 179mm x 114mm",
               "pageOptions": {
                   "pageWidth": "179mm",
                   "pageHeight": "114mm",
                   "pageMarginTop": "55mm",
                   "pageMarginBottom": "15mm",
                   "pageMarginLeft": "90mm",
                   "pageMarginRight": "18mm"
               }
            },
					},
					currentPrintProfile : "Envelope 179x114",
					screenPageSize: 24,
					vat : 0
				},

				setInProgress : function(v){
					if (this.inProgressSetter){
						this.inProgressSetter(v);
					}
				}

			};

			// This is only for short calculations, no long running stuff
			cfg._onLoaded = function(){
				dimUnit.setDefaults(cfg.units.default, cfg.units.allowed);
			}
			cfg._setDefaults = function(){
				for(var key in cfg._defaults){
					if(typeof cfg[key] == 'undefined'){
						cfg[key] =  _.clone(cfg._defaults[key]);
					}
				}
			}

			var deepExtend = function (dst, src){
        for (var prop in src) {
					if (typeof dst[prop] == 'object' && typeof src[prop] == 'object'){
						deepExtend(dst[prop], src[prop]);
				 	} else {
				 		dst[prop] = src[prop];
				 	}
        }
			}

			cfg.refreshKey = function(key, value){
				if (cfg[key] && typeof cfg[key] == 'object' && typeof value == 'object'){
					if(cfg._defaults[key]){
						cfg[key] =  _.clone(cfg._defaults[key]);
					}
					deepExtend(cfg[key], value);
				} else{
					cfg[key] = value;
				}
			}

			cfg.load = function(cb) {
				cfg.setInProgress(true);
				couchr.get(dbUrl + '_design/app/_view/config?include_docs=true', function (err, doc) {
					if(err) {
						console.error(err);
					}
					for(var i in doc.rows){
						var key = doc.rows[i].doc.key;
						var value = doc.rows[i].doc.value;
						cfg.refreshKey(key, value);
						//console.log("Set/update " + key + " to " , value);
					}
					cfg._initialized = true;
					cfg._onLoaded();
					if(cb){
						cb(cfg);
					}
					cfg.setInProgress(false);
				});
			};

			cfg.save = function(key,value, updateOrReplace, cb){
				if(typeof updateOrReplace == 'function'){
					cb = updateOrReplace;
					updateOrReplace = 'update';
				}

				for(var i in value){
					if(typeof i == 'string' && i.indexOf('$$') == 0){
						delete value[i]
					}
				}

				cfg.setInProgress(true);
				var valueNodes = key.split('.');
				var docKey  = valueNodes.shift();

				var docId = 'config-' + docKey;
				var updateDoc = function(oldVal, newVal){
					var newDoc = oldVal || {
						_id: docId,
						objType : 'config',
						key : docKey,
						value : {}
					};
					var node = newDoc;
					var key = 'value';
					for(var i in valueNodes){
						if(typeof node[key][ valueNodes[i] ] == 'undefined'){
							node[ key ][ valueNodes[i] ] = {}
						}
						node = node[ key ];
						key = valueNodes[i];
					}
					if(typeof node[key] == 'object' && (newVal && typeof newVal == 'object') && updateOrReplace == 'update'){
							deepExtend(node[key], newVal);
					} else {
						if(newVal != null){
							node[key] = newVal;
						} else {
							delete node[key];
						}
					}
					return newDoc;
				}
				couchr.get(dbUrl + docId, function (err, doc) {
					var newDoc = updateDoc(doc,value);
					if(newDoc.value == null){
						couchr.del(dbUrl + docId+'?rev=' + newDoc._rev, function (err, doc) {
							console.log("Deleted config key: " + newDoc.key);
							delete cfg[docKey];
							if(cb){
								cb();
							}
							cfg.setInProgress(false);
						});
					} else {
						couchr.put(dbUrl + docId, newDoc ,function (err, doc) {
							console.log("Saved config key :" + newDoc.key);
							cfg.refreshKey(docKey, newDoc.value);

							if(cb){
								cb();
							}
							cfg.setInProgress(false);
						});
					}
				});
			};

			cfg._setDefaults();
			cfg._onLoaded();
			return cfg;
	 }
);
