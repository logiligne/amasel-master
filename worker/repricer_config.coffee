_ = require 'underscore'
db = require './db'
util = require 'util'

#  "config": {
#      "minPrice": "2.00",
#      "maxPrice": "5.00",
#      "active": true,
#      "underLowest": true
#  }

class RepricerConfig
	constructor:() ->
		@items = []

	dump:()->
		util.inspect(@, null,100)

	_index:()->
		for item in @items
			do (item)=> Object.defineProperty(@, item.SKU, { get: ()-> item.config })

	fromObject:(dict)->
		if Array.isArray(dict)
			list = dict
		else
			list = Object.keys(dict)
		for sku in list
			@items.push(
				SKU: sku
				config:
					minPrice: dict[sku]?.minPrice ? null
					maxPrice: dict[sku]?.maxPrice ? null
					active: dict[sku]?.active ? true
					underLowest: dict[sku]?.underLowest ? false
			)
		@_index()
		Promise.resolve(@)

	fromDbConfig:(dbObj, validSKUs)->
		for d in dbObj.rows
			if d.doc.config.active and d.doc.SKU of validSKUs
				@items.push(d.doc)
			# if !(d.doc.SKU of validSKUs)
			# 	console.error "IVALID SKU #{d.doc.SKU}"
		@_index()

	loadFromDb:()->
		Promise.all([
			new Promise (resolve, reject)->
				db.view 'app', 'repricer_config', {reduce: false, include_docs: true}, (err,body)=>
					if err
						reject(err)
						return
					resolve({repricer_config: body})
			new Promise (resolve, reject)->
				db.view 'app', 'products', {reduce: false, include_docs: false}, (err,body)=>
					if err
						reject(err)
						return
					resolve({products: body})
		]).then (res)=>
			products = res[0].products ?  res[1].products
			repricer_config = res[0].repricer_config ?  res[1].repricer_config
			validSKUs = _.object([item.key, true] for item in products.rows)
			@fromDbConfig(repricer_config, validSKUs)
			return @

	listSKUs: ()->
		(item.SKU for item in @items)

module.exports = RepricerConfig
