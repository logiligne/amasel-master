log = require('./log')()
ThrottledFetcher = require './throttled_fetcher'
_ = require 'underscore'
util = require ('util')

class WaitForFeed extends ThrottledFetcher
	secondsToRefill1: 60
	constructor: (client, @feedId, @resultAvailable) ->
		super(client, @feedId)

	doFetch: (params)->
		log.verbose "WaitForFeed[#{@feedId}]: fetch ids ", params
		@client.getFeedSubmissionResult params, (obj,res) => @_processResult(obj,res)

	processResult: (res)->
		if res?.error?.Code is 'FeedProcessingResultNotReady'
			@retryLastCall 30
			return
		#console.log util.inspect(res,false,15)
		if res?.response
			@resultAvailable? res?.response
		else if res?.error
			log.error "WaitForFeed[#{@feedId}]: getFeedSubmissionResult error"
			@resultAvailable? null,res.error
		else
			log.error "WaitForFeed[#{@feedId}]: (no more retries) Invalid getFeedSubmissionResult response", util.inspect(res,false,5)



module.exports = WaitForFeed
