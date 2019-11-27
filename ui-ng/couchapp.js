 var couchapp = module.parent.require('couchapp')
  , path = require('path')
  ;

ddoc =
  { _id:'_design/app'
  , rewrites :
    [ {from:"/", to:'index.html'}
    , {from:"/api", to:'../../'}
    , {from:"/api/*", to:'../../*'}
    , {from:"/*", to:'*'}
    ]
  }
  ;

ddoc.views = {};

ddoc.views.config = {
  map: function (doc) {
		if (doc.objType == 'config') {
			emit(null, null);
		}
	},
}

ddoc.views.unshipped_orders = {
  map: function (doc) {
		if (doc.objType == 'order' && (doc.OrderStatus == 'Unshipped' || doc.OrderStatus == 'PartiallyShipped')) {
			emit(doc.PurchaseDate, null);
		}
	},
}

ddoc.views.orders_items_by_order_id = {
  map: function(doc) {
	  if(doc.objType == 'orderItem'){
		  emit(doc.AmazonOrderId , null);
	  }
	}
}

ddoc.views.orders_flags = {
  map: function(doc) {
	  if(doc.objType == 'orderFlags'){
		  emit(doc.AmazonOrderId , null);
	  }
	}
}

ddoc.views.purchase_orders = {
  map: function (doc) {
		if (doc.objType == 'purchaseOrder') {
			emit(null, null);
		}
	},
}

//
ddoc.views.products = {
  map: function (doc) {
		if (doc.objType == 'item') {
			emit(doc.SKU, null);
		}
	}
}

ddoc.views.products_info = {
  map: function (doc) {
		if (doc.objType == 'itemInfo') {
			emit(doc.ASIN, null);
		}
	}
}

ddoc.views.repricer_config = {
  map: function (doc) {
		if (doc.objType == 'repricerConfig') {
			emit(doc.SKU, null);
		}
	}
}

ddoc.views.repricer_history = {
  map: function (doc) {
  	if (doc.objType == 'syncOperation' && doc.objSubtype == 'price' && doc.syncStatus == "FINISHED") {
  		if(doc.newPrices.length > 0 || ( doc.skippedRepricing && Object.keys(doc.skippedRepricing).length > 0) ) {
  			emit(doc.startTime, {
          startTime: doc.startTime,
          endTime: doc.endTime,
          objType: doc.objType,
          objSubtype: doc.objSubtype,
          newPrices: doc.newPrices,
          skippedRepricing: doc.skippedRepricing,
          deltaPrices: doc.deltaPrices,
          syncStatus: doc.syncStatus
        });
        //emit(doc.startTime, null);
  		}
  	}
	}
}

ddoc.views.billing_reports = {
  map: function (doc) {
		if (doc.objType == 'billing' && doc.objSubtype == 'billingReport') {
			emit(doc.startDate, null);
		}
	}
}


couchapp.loadAttachments(ddoc, path.join(__dirname, 'app'));

module.exports = ddoc;
