log = require('./log')()
ThrottledFetcher = require './throttled_fetcher'
OrderItem= require('./sync/order_item')
util = require 'util'

class OrderItemsFetcher extends ThrottledFetcher
	secondsToRefill1: 3 # 2 second with 1 sec tollerance 

	doFetch: (params)->	
		log.info "fetchOrderItems: fetch for  ", params
		@client.listOrderItems params.AmazonOrderId, (obj,res) => @_processResult(obj,res)

	processResult: (items, res)->
		if items 
			if not Array.isArray(items)
				items = [ items ]
			log.info "fetchOrderItems: Got #{ items.length } order items"
			@events.emit('hasResults', items)
			for item in items
					item.objSource = 'amazon'
					item.objType = 'orderItem'
					o = new OrderItem(item,res.result.AmazonOrderId)
					o.proxyEventsToFetcher(@)
					o.sync()
		else if res?.responseType isnt 'Error'
			log.info "fetchOrderItems: Empty listOrderItems response"
		else
			log.error "fetchOrderItems: Invalid listOrderItems response", util.inspect(res,false,5)	


module.exports = OrderItemsFetcher
