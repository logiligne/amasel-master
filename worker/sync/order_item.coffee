Syncable = require './syncable'

class OrderItem extends Syncable
	idField: 'OrderItemId'
	modifiedFields: ['QuantityOrdered', 'QuantityShipped', 'GiftMessageText','ItemPrice']
	getDbId: () ->
		return "order-item-#{ @obj['AmazonOrderId'] }-#{ @obj[@idField] }"
	constructor: (obj, amazonOrderId)->
		super obj
		@obj.AmazonOrderId = amazonOrderId
	
module.exports = OrderItem