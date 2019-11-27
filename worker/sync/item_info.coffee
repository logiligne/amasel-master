Syncable = require './syncable'

class ItemInfo extends Syncable
	idField: 'ASIN'
	modifiedFields: ['feature','imageSmall','title']
	getDbId: () ->
		return "item-info-#{ @obj['ASIN'] }"
	@fromProduct:(product)->
		obj = {}
		obj['lang']    = product["AttributeSets"]["ns2:ItemAttributes"]["@"]["xml:lang"]
		obj['feature'] = product["AttributeSets"]["ns2:ItemAttributes"]["ns2:Feature"]
		obj['imageSmall'] = product["AttributeSets"]["ns2:ItemAttributes"]["ns2:SmallImage"]["ns2:URL"]
		obj['imageBig'] = obj['imageSmall'].replace(/SL75/,'SL500') if obj['imageSmall']
		obj['title'] = product["AttributeSets"]["ns2:ItemAttributes"]["ns2:Title"]
		obj['ASIN'] = product["Identifiers"]["MarketplaceASIN"]["ASIN"]
		obj['MarketplaceId'] = product["Identifiers"]["MarketplaceASIN"]["MarketplaceId"]
		obj['objSource'] = 'amazon'
		obj['objType'] = 'itemInfo'
		return new ItemInfo(obj)

module.exports = ItemInfo