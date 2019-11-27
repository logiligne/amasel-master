log = require('./log')()
ThrottledFetcher = require './throttled_fetcher'
ItemInfo = require('./sync/item_info')
_ = require 'underscore'
util = require ('util')

class ProductInfoFetcher extends ThrottledFetcher
	secondsToRefill1: 2 # 3 per second
	refills: {
		GetLowestOfferListingsForSKU : 2,
		GetLowestOfferListingsForASIN: 2,
		GetMyPriceForSKU: 2,
		GetMyPriceForASIN: 2,
	}
	constructor: (client, params, @requestName ,@resultAvailable) ->
		@requestName = @requestName.charAt(0).toLowerCase() + @requestName.substr(1)
		if @refills[@requestName]
			@secondsToRefill1 = @refills[@requestName]
		@fetcherTag = "fetch-#{@requestName}"
		super(client, params)

	doFetch: (params)->
		log.verbose "fetch[#{@requestName}]: fetch ids ", params
		if @requestName == 'getLowestOfferListingsForSKU'
			@client[@requestName] params, null, true, (obj,res) => @_processResult(obj,res)
		else
			@client[@requestName] params, null,  (obj,res) => @_processResult(obj,res)

	processResult: (res)->
		items = res?.result
		if items
			if not Array.isArray(items)
				items = [ items ]
			log.verbose "fetch[#{@requestName}]: Got #{ items.length } objects"
			@events.emit('hasResults', items)
			for itemObj in items
				log.debug "fetch[#{@requestName}]: item = ",JSON.stringify(itemObj)
				@resultAvailable? itemObj
		else if res?.responseType isnt 'Error'
			log.verbose "fetch[#{@requestName}]: Empty response"
		else
			log.verbose "fetch[#{@requestName}]: (no more retries) Invalid response", util.inspect(res,false,5)



module.exports = ProductInfoFetcher
