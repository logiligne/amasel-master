_ = require 'underscore'
db = require './db'
RepricerResult = require './repricer_result'

class RepricerStrategy
	constructor:(@repriceConfig, @myPrices, @lowestOffers) ->

	repriceItemsDefault: ->
		@newPrices = [] # items.push({'SKU': s[1],'StandardPrice': s[2]})
		@deltaPrices = {}
		@skippedRepricing = {}
		@myPricesCalculated = {}
		@lowestOfferCalculated = {}
		for sku,myPrice of @myPrices
			unless @repriceConfig[sku].active
				@skippedRepricing[sku] = RepricerResult.ITEM_INACTIVE
				continue
			myPriceCents = Math.round(myPrice.landedPrice * 100)
			@myPricesCalculated[sku] = myPriceCents
			myListingPriceCents = Math.round(myPrice.listingPrice * 100)
			offsetCents = 0
			if @repriceConfig[sku].underLowest
				offsetCents = -1
			if @repriceConfig[sku].offset
				offsetCents = Math.round(parseFloat(@repriceConfig[sku].offset) * 100)
			if @lowestOffers[sku]
				lowestPriceCents = Math.round(@lowestOffers[sku].landedPrice * 100)
			else
				# no lowest offers, we are the only selller , set the maximum price
				if @repriceConfig[sku].maxPrice
					lowestPriceCents = Math.round(parseFloat(@repriceConfig[sku].maxPrice) * 100)
					offsetCents = 0
				else
					@skippedRepricing[sku] = RepricerResult.NEED_RAISE_NO_MAX_PRICE
					continue
			@lowestOfferCalculated[sku] = lowestPriceCents
			#console.log "#{myPriceCents} != #{lowestPriceCents} + #{offsetCents} "
			if myPriceCents != (lowestPriceCents + offsetCents)
				needToLower = myPriceCents > (lowestPriceCents + offsetCents)
				needToRaise = myPriceCents < (lowestPriceCents + offsetCents)
				if needToLower
					# we need to lower the price, minPrice is mandatory
					unless @repriceConfig[sku].minPrice
						@skippedRepricing[sku] = RepricerResult.NEED_LOWER_NO_MIN_PRICE
						continue
				if needToRaise
					# we need to raise the price, maxPrice is mandatory
					unless @repriceConfig[sku].maxPrice
						@skippedRepricing[sku] = RepricerResult.NEED_RAISE_NO_MAX_PRICE
						continue
				minPriceCents = 0
				if @repriceConfig[sku].minPrice
					minPriceCents = Math.round(parseFloat(@repriceConfig[sku].minPrice) * 100)
				maxPriceCents = 999999999
				if @repriceConfig[sku].maxPrice
					maxPriceCents = Math.round(parseFloat(@repriceConfig[sku].maxPrice) * 100)
				#quick function to add new price entry, to avoid duplication
				addNewPriceEntry = (basePriceCents)=>
					deltaPrice = ( basePriceCents ) -  myPriceCents
					newPriceCents = myListingPriceCents + deltaPrice
					if newPriceCents >= 1
						@newPrices.push({'SKU': sku,'StandardPrice': Number((newPriceCents)/100).toFixed(2)})
						@deltaPrices[sku] = Number(deltaPrice/100).toFixed(2)
					else
						@skippedRepricing[sku] = RepricerResult.NEW_PRICE_BELOW_0_01
				if minPriceCents <= (lowestPriceCents + offsetCents) <= maxPriceCents
					# set new price in min/max range
					addNewPriceEntry( lowestPriceCents + offsetCents )
				else if needToLower and (( myPriceCents > minPriceCents ) or (@repriceConfig[sku].strictRange and ( myPriceCents != minPriceCents )))
					# set new min price
					addNewPriceEntry( minPriceCents )
				else if needToRaise and (( myPriceCents < maxPriceCents ) or (@repriceConfig[sku].strictRange and ( myPriceCents != maxPriceCents )))
					# set new max price
					addNewPriceEntry( maxPriceCents )
				else
					@skippedRepricing[sku] = RepricerResult.NOT_IN_RANGE
			else
				@skippedRepricing[sku] = RepricerResult.ALREADY_LOWEST
		for sku,myPrice of @lowestOffers
			unless @myPrices[sku]
				@skippedRepricing[sku] = RepricerResult.MY_PRICE_MISSING

module.exports = RepricerStrategy
