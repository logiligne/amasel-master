log = require('./log')()
events = require "events"
_ = require 'underscore'
WaitAsyncWork = require('./wait_async_work')

class ThrottledFetcher
	secondsToRefill1: 60
	lastCall : null
	autoStart: true

	constructor: (client, params) ->
		@client = client
		params = params ? []
		if not _.isArray(params)
			@params = [ params ]
		else
			@params = params.slice(0)
		@events = new events.EventEmitter()
		@throttled = false
		@doRetry = false
		@doRetryDelay = 200
		@retry = 0
		@maxRetries = 5
		@working = false
		@waitAsync = new WaitAsyncWork(@fetcherTag)

	initWaitAsync: ->
		@waitAsync.attachToThrottledFetcher( @ )

	queueFetch: (params) ->
		@params.push(params)
		if not @working and @autoStart
			@fetch()

	queueLength: ()->
		return @params.length

	retryLastCall: (delaySeconds) ->
		@retry++
		if @retry <= @maxRetries
			@doRetry = true
		else
			@doRetry = false
		if delaySeconds > 0
			@doRetryDelay = delaySeconds*1000
		else
			@doRetryDelay = 200
		return @doRetry

	fetch: () ->
		if @params.length > 0
			@working = true
			param = @params[0]
			@params.shift()
			@events.emit('hasMoreResults')
			@lastCall  = => @doFetch(param)
			@lastCall()
		else
			@events.emit('end')
			@working = false

	getProcessCallback: () ->
		return (obj,res) => @_processResult(obj,res)

	_processResult: (obj, res)->
		res = obj if not res?
		if res?.responseType is 'Error' and res?.error?.Code is 'RequestThrottled'
			# retry with delay
			log.debug "Request throttled, retrying after: #{ @secondsToRefill1 }s"
			@events.emit('throttled')
			@throttled = true
			setTimeout @lastCall, @secondsToRefill1*1000
		else
			@doRetry = false
			@events.emit('processResult', obj)
			@processResult obj, res
			@events.emit('processResultEnd', obj)
			if @doRetry
				log.debug "Retry requested, scheduling retry after #{ @doRetryDelay }ms"
				setTimeout @lastCall, @doRetryDelay
			else if res?.nextToken?
				@events.emit('hasMoreResults')
				@lastCall = res.getNext
				if @throttled
					log.debug "Throttled mode, nextCall after: #{ @secondsToRefill1 }s"
					setTimeout @lastCall, @secondsToRefill1*1000
				else
					res.getNext()
			else
				@fetch()

	processResult: (obj, res)->
		log.error "Implement result processing for: ", {obj: obj, res: res}

module.exports = ThrottledFetcher
