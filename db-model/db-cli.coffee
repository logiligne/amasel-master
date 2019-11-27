Table = require 'cli-table'

model = require('./src/db-model').get('default','http://localhost:5984/lollipop')


# model.fetch(["PurchaseOrders"]).then (model)->
# 	console.log model.purchaseOrders
# model.fetch(["Products", "UnshippedOrders"]).then (model)->
# 	#console.log 'MODEL:', model
# 	#console.log 'UO:', model.unshippedOrders
# 	table = new Table({ head: ['OrderId' , "Item SKU", "Item Title", "Total", "Flags"] })
# 	filterList = [
# 		{field: 'AmazonOrderId', filters:{startsWith: '305'}}
# 		'or'
# 		{field: 'AmazonOrderId', filters:{startsWith: '304'}}
# 	]
# 	model.unshippedOrders.filter(filterList).forEach (v,k)->
# 		table.push [
# 			k,
# 			(model.products.get(i.ASIN).SKU for i in v.items).join("\n"),
# 			(i.Title for i in v.items).join("\n"),
# 			( i.ItemPrice.Amount + ' + ' +i.ShippingPrice.Amount for i in v.items).join("\n"),
# 			if v.flags then v.flags.join(",") else "",
# 		]
# 	console.log '--'
# 	console.log table.toString()
# 	console.log model.unshippedOrders.getGroups()
# 	console.log model.unshippedOrders.getGroups('flags.')
# 	console.log model.unshippedOrders.getKeysInGroup(model.unshippedOrders.getGroups()[0])
#
# .catch (err)->
# 	console.error 'ERROR:',err
# 	console.error err.stack if err.stack


# model.fetch(["Products","RepricerConfig"]).then (model)->
# 	#console.log JSON.stringify(model.products.asList().slice(50))
# 	#process.exit(0)
# 	table = new Table({ head: ['SKU' , 'ASIN',  "Price", "Quantity", 'Repricer'] })
# 	filterList = [
# 		{field: 'SKU', filters:{startsWith: 'ak 200'}}
# 	]
# 	model.products.filter(filterList).sort(['SKU']).forEach (v,k)->
# 		table.push [
# 			v.SKU,
# 			v.ASIN
# 			v.Price
# 			v.Quantity
# 			JSON.stringify(v.repricerConfig ? "")
# 		]
# 	console.log table.toString()
#
# .catch (err)->
# 	console.error 'ERROR:',err
# 	console.error err.stack if err.stack

model.fetch(["RepricerHistory"]).then (model)->
	table = new Table({ head: ['SKU' ,'Time', 'New price',  "Delta", "No change reason"] })
	filterList = [
		{field: 'time', filters:{greaterOrEqual: new Date("2015-04-04T08:00:03.041Z")}}
		{field: 'time', filters:{lessOrEqual: new Date("2015-04-04T08:30:02.383Z")}}
	]
	#model.repricerHistory.getAllByIndex('SKU','ak 2004').forEach (v,k)->
	model.repricerHistory.filter(filterList).sort(['SKU']).forEach (v,k)->
		table.push [
			v.SKU ? "",
			v.time ? ""
			v.newPrice ? ""
			v.deltaPrice ? ""
			v.skippedReason ? ""
		]
	console.log table.toString()

.catch (err)->
	console.error 'ERROR:',err
	console.error err.stack if err.stack
