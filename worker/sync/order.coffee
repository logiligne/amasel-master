Syncable = require './syncable'

class Order extends Syncable
	idField: 'AmazonOrderId'
	modifiedFields: ['LastUpdateDate']
	getDbId: () ->
		return "order-#{ @obj[@idField] }"
	
module.exports = Order