PouchDB = require('pouchdb')
_ = require('lodash')
IndexedCollection = require('./indexed-collection')
AmazonTransaction = require('./amazon-transaction')
Selection = require('./selection')

class DbModel
	DESIGN_DOC: 'app'
	PRODUCTS_COLUMNS: ["SKU", "ASIN", "Price", "Quantity"]
	PRODUCTS_INFO_COLUMNS: [
			'ASIN', 'MarketplaceId', 'feature'	,
			'imageBig', 'imageSmall','lang' ,'title']
	ORDERS_COLUMNS: [
		"ShipmentServiceLevelCategory", "OrderTotal", "ShipServiceLevel",
		"LatestShipDate", "MarketplaceId", "SalesChannel", "ShippingAddress",
		"ShippedByAmazonTFM", "OrderType", "FulfillmentChannel", "BuyerEmail",
		"OrderStatus", "BuyerName", "LastUpdateDate", "EarliestShipDate",
		"PurchaseDate", "NumberOfItemsUnshipped", "NumberOfItemsShipped",
		"PaymentMethod","AmazonOrderId",
	]
	ORDER_ITEMS_COLUMNS: [
		"OrderItemId", "GiftWrapPrice", "QuantityOrdered", "GiftWrapTax",
		"SellerSKU", "Title", "ShippingTax", "ShippingPrice",
		"ItemTax", "ItemPrice", "PromotionDiscount", "ConditionId",
		"ASIN", "QuantityShipped", "ConditionSubtypeId", "ShippingDiscount",
		"AmazonOrderId",
	]
	ORDER_FLAGS_COLUMNS: ["AmazonOrderId" , "flags"]
	PURCHASE_ORDERS_COLUMNS: [ "Quantity", "SKU"]
	constructor:(config) ->
		@db = new PouchDB(config)
		@_clear()

	_clear: ()->
		@unshippedOrders = new IndexedCollection({
			primaryIndex:"AmazonOrderId"
			autoGroups: {
				"flags.*" : (value, key) -> value?.flags
			}
		})
		@products = new IndexedCollection({primaryIndex:"ASIN",columnIndexes:["SKU"]})
		@purchaseOrders = new IndexedCollection({primaryIndex:"SKU"})
		@billingReports = []
		@repricerHistory = new IndexedCollection({columnIndexes:["SKU", "time"]})
		@productSelection = new Selection()
		@productPriceChanges = new AmazonTransaction()
		@productQuantityChanges = new AmazonTransaction()
		@productSelection.refEvents('_selection_link').on 'changed',(key, value)=>
			if value
				@products.addToGroup('selection', @products.getByIndex('SKU',key).ASIN )
			else
				@products.removeFromGroup('selection', @products.getByIndex('SKU',key).ASIN )

	_processResult: (dataList)->
		dataList = [ dataList ] unless Array.isArray(dataList)
		for data in dataList
			#console.log 'DATA:', data
			for row in data.rows
				#console.log 'ROW:', row
				doc = row.value ? row.doc
				unless doc.objType?
					throw new Error('Unknown data object:' + JSON.stringify(row))
				switch doc.objType
					when "item"
						@products.update(doc.ASIN, _.pick(doc, @PRODUCTS_COLUMNS))
					when "itemInfo"
						@products.update(doc.ASIN, _.pick(doc, @PRODUCTS_INFO_COLUMNS))
					when "repricerConfig"
						ASIN = @products.getByIndex('SKU',doc.SKU)?.ASIN
						if ASIN
							@products.update(ASIN, {repricerConfig: doc.config})
					when "order"
						if doc.OrderStatus is  "Unshipped"
							@unshippedOrders.update(doc.AmazonOrderId , _.pick(doc, @ORDERS_COLUMNS))
						else
							@unshippedOrders.delete(doc.AmazonOrderId)
					when "orderItem"
						if @unshippedOrders.has(doc.AmazonOrderId)
							@unshippedOrders.update(
								doc.AmazonOrderId
								{items:[ _.pick(doc, @ORDER_ITEMS_COLUMNS) ]}
								(value, other) -> if Array.isArray(value) then value.concat(other) else other
							)
					when "orderFlags"
						if @unshippedOrders.has(doc.AmazonOrderId)
							flags = if Array.isArray(doc.flags) then doc.flags else [doc.flags]
							@unshippedOrders.update(
								doc.AmazonOrderId
								{flags:flags}
								(value, other) -> if Array.isArray(value) then value.concat(other) else other
							)
					when "billing"
						if doc.objSubtype is "billingReport"
							@billingReports.push( doc );
					when "purchaseOrder"
						@purchaseOrders.update(doc.SKU, _.pick(doc, @PURCHASE_ORDERS_COLUMNS) )
					when "syncOperation"
						if doc.objSubtype is "price" and doc.syncStatus is "FINISHED"
							makeKey = (v)-> v.SKU + '-' + v.time.toISOString()
							for newPrice,idx in doc.newPrices
								v =
									SKU : newPrice.SKU
									time : new Date(doc.endTime),
									deltaPrice: doc.deltaPrices?[newPrice.SKU],
									newPrice: newPrice.StandardPrice
								v.id = makeKey(v)
								@repricerHistory.update(v.id, v)
							for sku, reason of doc.skippedRepricing
								v =
									SKU : sku
									time : new Date(doc.endTime),
									skippedReason : reason
								v.id = makeKey(v)
								@repricerHistory.update(v.id, v)

		dataList

	_fetchView: (viewName, options={})->
		options.reduce ?= false
		options.include_docs ?= true
		@db.query(@DESIGN_DOC + '/' + viewName, options)
			.then((result)=> @_processResult(result))

	fetch: (dataTags, options=[])->
		dataTagList = if Array.isArray(dataTags) then dataTags else [dataTags]
		if dataTagList.length == 0
		 	return new Promise((resolve, reject)-> reject(new Error('No data tag specified in fetch: '+ dataTag)))
		for dataTag,idx in dataTagList
			fnName = 'fetch' + dataTag
			unless typeof @[fnName] is 'function'
				return new Promise((resolve, reject)-> reject(new Error('Invalid data tag in fetch: '+ dataTag)))
			o = if idx < options.length then options[idx] else {}
			if promise
				promise = promise.then (value)=> @[fnName](o)
			else
				promise = @[fnName](o)
		promise


	fetchUnshippedOrders:(options={}) ->
		@_fetchView('unshipped_orders', options).then (result)=>
			keys = @unshippedOrders.keys()
			Promise.all([
				@_fetchView('orders_items_by_order_id', {keys: keys})
				@_fetchView('orders_flags', {keys: keys})
			]).then(()=> @)

	fetchBillingReports:(options={}) ->
		@_fetchView('billing_reports', options).then (result)=> @

	fetchProducts: (options={})->
		Promise.all([
			@_fetchView('products')
			@_fetchView('products_info')
		]).then(()=> @)

	fetchPurchaseOrders: (options={})->
		@_fetchView('purchase_orders', options).then (result)=> @

	fetchRepricerConfig: (options={})->
		@_fetchView('repricer_config', options).then (result)=> @

	fetchRepricerHistory: (options={})->
		options.include_docs ?= false
		@_fetchView('repricer_history', options).then (result)=> @

	saveFlags: (orderId, options={})->
		docId = 'order-flags-' + orderId
		newDoc =
			_id: docId,
			AmazonOrderId : orderId
			objType : 'orderFlags'
			flags :  model.unshippedOrders.get(orderId).flags
		db.get(docId).then (doc)->
			newDoc._rev = doc._rev
			if !newDoc.flags or newDoc.flags.length==0
				db.remove docId, newDoc._rev
			else
				db.put newDoc
		.catch (err)->
			if err.status == 404 and reason is 'missing'
				db.put newDoc
			else
				throw err

INSTANCES = {}

module.exports =
	DbModel : DbModel
	get: (name, config)->
		console.log 'DbModel.get:',name, config
		if config == null
			config = name
			name = JSON.stringify(config)
		if name of INSTANCES
			return INSTANCES[name]
		INSTANCES[name] = new DbModel(config)
