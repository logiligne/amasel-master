log = require('./log')()
ThrottledFetcher = require './throttled_fetcher'
Order= require('./sync/order')
CountryCodes = require './country_codes'
util = require 'util'

class OrdersFetcher extends ThrottledFetcher
	secondsToRefill1: 61 # 60 second with 1 sec tollerance

	doFetch: (params)->	
		log.info "OrdersFetcher listOrders ", params
		@client.listOrders params, @getProcessCallback()

	processResult: (orders, res)->
		if orders 
			if not Array.isArray(orders)
				orders = [ orders ]
			log.info "fetchOrders: Got #{ orders.length } orders"
			#log.info "res :", JSON.stringify(res)
			#log.info "otrders #{ typeof orders }:", orders
			@events.emit('hasResults', orders)
			for order in orders
					order.objSource = 'amazon'
					order.objType = 'order'
					if order.ShippingAddress?.CountryCode?
						if not order.ShippingAddress?.Country?
							order.ShippingAddress.Country = CountryCodes[order.ShippingAddress.CountryCode]
					o = new Order(order)
					o.proxyEventsToFetcher(@)
					o.sync()
		else if res?.responseType isnt 'Error'
			log.info "fetchOrders: Empty ListOrders response"
		else
			log.error "fetchOrders: Invalid ListOrders response", util.inspect(res,false,5)	


module.exports = OrdersFetcher