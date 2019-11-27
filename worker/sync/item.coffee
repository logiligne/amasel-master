Syncable = require './syncable'

class Item extends Syncable
	idField: 'SKU'
	modifiedFields: ['Price', 'Quantity']
	getDbId: () ->
		return "item-#{ @obj['ASIN'] }-#{ @obj[@idField] }"

module.exports = Item