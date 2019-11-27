db = require '../db'
log = require('../log')()
events = require "events"
_ = require 'underscore'

#cnt = 0

class Syncable
	idField: null
	modifiedFields: []
	getDbId: () ->
		return @obj[@idField]
	constructor: (@obj) ->
		@events = new events.EventEmitter()
		#@cnt = cnt++
	isUpdated: (dbObj) ->
		for f in @modifiedFields
			return true if not _.isEqual(@obj[f], dbObj[f])
		return false
	updateReason: (dbObj) ->
		s = ""
		for f in @modifiedFields
			if not _.isEqual(@obj[f], dbObj[f])
				s += "obj[#{f}]=(#{ JSON.stringify( @obj[f]) }) <=> db[#{f}]=(#{ JSON.stringify(dbObj[f]) }) ; "
		return s
	proxyEventsToFetcher: (fetcher) ->
		@events.on 'sync', (obj) =>
			#log.info "start sync object #{@cnt}"
			fetcher.events.emit 'startSyncObject', obj
		@events.on 'update', (obj) =>
			#log.info "update object #{@cnt}"
			fetcher.events.emit 'updateObject', obj
		@events.on 'insert', (obj) =>
			#log.info "insert object #{@cnt}"
			fetcher.events.emit 'createObject', obj
		@events.on 'samesame', (obj) =>
			#log.info "samsame object #{@cnt}"
			fetcher.events.emit 'samesameObject', obj
		@events.on 'error', (errObj) =>
			#log.info "err object #{@cnt}"
			fetcher.events.emit 'failedSyncObject', errObj.err, errObj

	sync: () ->
		@events.emit('sync', @obj)
		db.get @getDbId() ,(err, body) =>
			if err?.error is "not_found"
				# insert here
				db.insert @obj, @getDbId() , (err, body) =>
					log.info "Insert '#{ @getDbId() }' :" , body
					@events.emit('insert', @obj)
			else if err is null
				# compare here
				if @isUpdated(body)
					log.info "Update reason:", @updateReason(body)
					#log.info "Updating #{ @getDbId() }"
					for k,v of @obj
						#log.info "set body[#{k}] = #{v}"
						body[k] = v
					#log.info "after body:" , body
					db.insert body, @getDbId() , (err, body) =>
						log.info "Update '#{ @getDbId() }' :" , body
						@events.emit('update', @obj)
				else
						@events.emit('samesame', @obj)
			else
				# some other error happened ???
				log.error "Fetch error '#{ @getDbId() }' :", { err: err , body: body }
				@events.emit('error', { obj: @obj, err: err , body: body })

module.exports = Syncable
