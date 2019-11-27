util = require 'util'
_ = require 'underscore'
db = require './db'
log = require('./log')()
ProductInfoFetcher = require('./product_info_fetcher')

class RepricerFetcher
	constructor:(@config, @client) ->
		@params = []
		ss = 20
		skuList = @config.listSKUs()
		for i in [0...skuList.length] by ss
			@params.push skuList.slice(i,i+ss)

	fetchLowestOffers: ()->
		new Promise (resolve, reject)=>
			# Fetch the lowest current prices
			@lowestOffers = {}
			@lowestOffersAll = {}
			@lowestOffersMissing = {}
			lowestPriceFetch = new ProductInfoFetcher @client, @params, 'GetLowestOfferListingsForSKU', (obj) =>
				#console.log "**** lowest offer for #{ @params }" ,util.inspect(obj, null,10)
				if obj?['@']?['status'] != "Success"
					log.error "Failed GetLowestOfferListingsForSKU: %j" , obj , {}
					@lowestOffersMissing[obj?['@']?['SellerSKU']] = obj?['Error']?['Message'] ? JSON.stringify(obj)
					return
				# if obj?['@']?['status'] != "Success"
				# 	reject obj
				# 	return
				sku = obj['@']["SellerSKU"]
				listings = obj?['Product']?['LowestOfferListings']?["LowestOfferListing"]
				#console.log util.inspect(listings, false, 10)
				if not Array.isArray(listings)
					listings = [ listings ]
				for item in listings
					landedPrice = parseFloat(item?["Price"]?["LandedPrice"]?["Amount"])
					listingPrice = parseFloat(item?["Price"]?["ListingPrice"]?["Amount"])
					shippingPrice = parseFloat(item?["Price"]?["Shipping"]?["Amount"])
					if landedPrice
						if landedPrice < (@lowestOffers[sku] || 99999999999999)
							@lowestOffers[sku] = { landedPrice : landedPrice , listingPrice : listingPrice, shippingPrice: shippingPrice }
					else
						@lowestOffersMissing[sku] = true
						#log.error "Cannot find price for #{sku} in:", JSON.stringify(obj)
					if not @lowestOffersAll[sku]
						@lowestOffersAll[sku]=[]
					@lowestOffersAll[sku].push { landedPrice : landedPrice , listingPrice : listingPrice, shippingPrice: shippingPrice }
				log.debug "Lowest landed price for #{sku} is #{ @lowestOffers[sku] }"
			lowestPriceFetch.events.on 'end', =>
				resolve(@lowestOffers)
			lowestPriceFetch.initWaitAsync()
			lowestPriceFetch.fetch()

	fetchMyPrices: ()->
		new Promise (resolve, reject)=>
			# Fetch the my prices
			@myPrices = {}
			@myPricesMissing = {}
			myPriceFetch = new ProductInfoFetcher @client, @params, 'GetMyPriceForSKU', (obj) =>
				#console.log '**** my price' ,util.inspect(obj, null,10)
				if obj?['@']?['status'] != "Success"
					log.error "Failed GetMyPriceForSKU: %j" , obj , {}
					@myPricesMissing[obj?['@']?['SellerSKU']] = obj?['Error']?['Message'] ? JSON.stringify(obj)
					return
				# if obj?['@']?['status'] != "Success"
				# 	reject obj
				# 	return
				sku = obj['@']["SellerSKU"]
				offers = obj?['Product']?['Offers']?["Offer"]
				if not Array.isArray(offers)
					offers = [ offers ]
				for item in offers
					landedPrice = parseFloat(item?["BuyingPrice"]?["LandedPrice"]?["Amount"])
					listingPrice = parseFloat(item?["BuyingPrice"]?["ListingPrice"]?["Amount"])
					shippingPrice = parseFloat(item?["BuyingPrice"]?["Shipping"]?["Amount"])
					if landedPrice > 0 and listingPrice > 0
						@myPrices[sku] = { landedPrice : landedPrice , listingPrice : listingPrice, shippingPrice: shippingPrice }
					else
						@myPricesMissing[sku] = true
						#log.error "Cannot find price for #{sku} in:", JSON.stringify(item)
				log.debug "My price for #{sku} is #{ @myPrices[sku] }"
			myPriceFetch.events.on 'end', =>
				resolve(@myPrices)
			myPriceFetch.initWaitAsync()
			myPriceFetch.fetch()

	fetch:()->
		loffer = @fetchLowestOffers()
		myprice = @fetchMyPrices()
		Promise.all [loffer, myprice]

module.exports = RepricerFetcher
