log = require('./log')()
ThrottledFetcher = require './throttled_fetcher'
ItemInfo = require('./sync/item_info')
util = require 'util'

class ProductsFetcher extends ThrottledFetcher
	secondsToRefill1: 2 # 3 per second
	doFetch: (params)->
		log.verbose "fetchProducts: fetch ids ", params
		@client.getMatchingProductForId 'ASIN', params, (obj,res) => @_processResult(obj,res)
		#@client.getMatchingProduct params, (obj,res) => @_processResult(obj,res)

	processResult: (res)->
		items = res?.result
		if items
			if not Array.isArray(items)
				items = [ items ]
			log.verbose "fetchProducts: Got #{ items.length } products"
			@events.emit('hasResults', items)
			for itemObj in items
				#log.info ">>>",JSON.stringify(itemObj)
				item = itemObj["Products"]["Product"] #getMatchingProductForId
				#item = itemObj["Product"] #getMatchingProduct
				i = ItemInfo.fromProduct(item)
				i.proxyEventsToFetcher(@)
				i.sync()
		else if res?.responseType isnt 'Error'
			log.verbose "fetchProducts: Empty listOrderItems response"
		else
			if @retryLastCall()
				log.verbose "fetchProducts: Invalid listOrderItems retrying..."
			else
				log.error "fetchProducts: (no more retries) Invalid listOrderItems response", util.inspect(res,false,5)



module.exports = ProductsFetcher
