events = require "events"
log = require('./log')()

DEBUG=()->
if process.env["DEBUG_WAIT_ASYNC_WORK"]
	DEBUG=console.log


class WaitAsyncWork
	constructor: (@tag)->
		@events = new events.EventEmitter()
		@waitCount = 0
		@finishedCount = 0
		@_hold = false

	_checkForEnd: ->
		log.debug "WaitAsyncWork[#{@tag}]: check? waitedFor #{@waitCount} , processed #{@finishedCount} objects"
		if @finishedCount == @waitCount and not @_hold
			log.debug "WaitAsyncWork[#{@tag}]: end , waitedFor #{@waitCount} , processed #{@finishedCount} objects"
			#console.trace("asyncworkend")
			@events.emit 'end'

	waitFor: (num) ->
		@waitCount += num
		log.debug "WaitAsyncWork[#{@tag}]: waiting for #{ @waitCount }"

	finishedOne: ->
		@finishedCount++
		@_checkForEnd()
		log.debug "WaitAsyncWork[#{@tag}]: finishedOne"

	hold: ->
		@_hold = true

	unhold: ->
		old = @_hold
		@_hold = false
		if old
			@_checkForEnd()

	attachToThrottledFetcher: (fetcher) ->
		DEBUG "Attach to:", fetcher
		fetcher.events.on 'hasMoreResults',  =>
			DEBUG "hasMoreResults"
			@hold()
		fetcher.events.on 'processResultEnd',  =>
			DEBUG "processResultEnd"
			@unhold()
		fetcher.events.on 'startSyncObject',  =>
			DEBUG "startSyncObject"
			@waitFor 1
		fetcher.events.on 'samesameObject', =>
			DEBUG "samesameObject"
			@finishedOne()
		fetcher.events.on 'createObject', (order) =>
			DEBUG "createObject"
			@finishedOne()
		fetcher.events.on 'updateObject', (order) =>
			DEBUG "updateObject"
			@finishedOne()
		fetcher.events.on 'failedSyncObject', =>
			DEBUG "failedSyncObject"
			@finishedOne()
		fetcher.events.on 'end', =>
			DEBUG "end"
			@_checkForEnd()

module.exports = WaitAsyncWork
