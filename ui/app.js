 var couchapp = require('couchapp')
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

ddoc.views.unshipped_orders_with_items = {
  map: function(doc) {
	  if(doc.objType == 'order' && (doc.OrderStatus == 'Unshipped' || doc.OrderStatus == 'PartiallyShipped') ){
		  emit([doc.AmazonOrderId], 1);
	  }
	  if(doc.objType == 'orderItem' && (doc.QuantityOrdered != doc.QuantityShipped)){
		  emit([doc.AmazonOrderId, doc.ASIN ], 1);
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
  	if (doc.objType == 'syncOperation' && doc.objSubtype == 'price' ) {
  		if(doc.newPrices.length > 0 || ( doc.skippedRepricing && Object.keys(doc.skippedRepricing).length > 0) ) {
  			emit(doc.startTime, null);
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


/*

ddoc.filters = {}
ddoc.filters.pouch_sync =  function(doc, req) {
  if (doc.objType) {
    return true;
  } else {
    return false;
  }
}

ddoc.lists = {}
ddoc.lists.orders_with_items = function(head, req){
  start({
    "headers": {
      "Content-Type": "application/json"
     }
  });
	send('{"rows":[\n')
  // create an array for our result set
  var lastDoc = {AmazonOrderId: null};
	var rowCount = 0;

  while (row = getRow()) {
		var doc = row.doc;
		if(doc == null){
			send('{"error": "Unknown document"}, \n');
			continue;
		}
		if(doc.AmazonOrderId != lastDoc.AmazonOrderId && doc.objType == 'order') {
			// Starting new order send the last one
			if(lastDoc.AmazonOrderId != null) {
				send(JSON.stringify(lastDoc) + ",\n");
			  lastDoc = {AmazonOrderId: null};
				rowCount++;
			}
			lastDoc = doc;
			lastDoc.items = [];
		} else if (lastDoc.items != null){
			lastDoc.items.push(doc);
		}
  }

	if(lastDoc.AmazonOrderId != null) {
		send(JSON.stringify(lastDoc) + "\n");
		rowCount++;
	}
  send('],"total_rows":' + rowCount + ',"offset":0}');
}

ddoc.lists.products_with_info = function(head, req){
  start({
    "headers": {
      "Content-Type": "application/json"
     }
  });
	send('{"rows":[\n')
  // create an array for our result set
  var lastDoc = {ASIN: null};
	var rowCount = 0;

  while (row = getRow()) {
		var doc = row.doc;
		if(doc == null){
			send('{"error": "Unknown document"}, \n');
			continue;
		}
		if(doc.ASIN != lastDoc.ASIN) {
			// Starting new order send the last one
			lastDoc = doc;
		} else {
			if(rowCount != 0){
				send(",\n");
			}
			var r = {};
			for(var prop in lastDoc){
				r[prop] = lastDoc[prop];
			}
			for(var prop in doc){
				r[prop] = doc[prop];
			}
			send(JSON.stringify(r));
			rowCount++;
		}
  }

	if(lastDoc.AmazonOrderId != null) {
		send(JSON.stringify(lastDoc) + "\n");
		rowCount++;
	}
  send('],"total_rows":' + rowCount + ',"offset":0}');
}
*/
couchapp.loadAttachments(ddoc, path.join(__dirname, 'attachments'));

module.exports = ddoc;
