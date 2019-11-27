WaitForFeed = require './wait_for_feed'
log = require('./log')()
mws = require 'mws-js'

AmazonCredentials= require('./cfg').AmazonCredentials

class RepricerSetPrices
	constructor:(@newPrices) ->

	setPrices: () ->
		if @newPrices.length == 0
			return Promise.resolve(null)
		new Promise (resolve, reject)=>
			xmlFeeds = new mws.feeds.XMLFeeds(AmazonCredentials)
			feed = xmlFeeds.productPricing(@newPrices)
			feedClient = new mws.feeds.Client(AmazonCredentials)
			feedClient.submitFeed '_POST_PRODUCT_PRICING_DATA_', feed, null, false, (res) =>
				if res?.responseType is 'Error'
					log.error 'SubmitFeed: %j', res, {}
					reject(res)
					return
				feedId = res.result.FeedSubmissionInfo.FeedSubmissionId
				log.verbose "Submitted feed #{ feedId }"
				waitFeed = new WaitForFeed feedClient, feedId, (res, error)=>
					if error
						log.error error
						reject(error)
					else
						resolve({
							setPricesResult: res?.AmazonEnvelope?.Message?.ProcessingReport,
							setPricesResultRaw:res,
							setPricesError: res?.error
						})
				waitFeed.fetch()

module.exports = RepricerSetPrices
