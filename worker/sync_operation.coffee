_ = require 'underscore'
db = require './db'
log = require('./log')()


class SyncOperation
	opKeys: [ 'startTime','endTime',
						'syncStatus',
						'description',
						'objSource', 'objType', 'objSubtype'
						'params', 'hasErrors',
						'errors', 'messages', ]
	opName: 'sync-generic'
	constructor:(@syncId, @description, @syncView) ->
		@startTime = null
		@syncDocId = @opName + '-'+ (@syncId ? (new Date().toISOString()))
		@endTime = null
		@errors = []
		@messages = []
		@syncStatus = 'PENDING'
		@objSource = 'manual'
		@objType = 'syncOperation'
		@objSubtype = 'undefined'
		@_skipDbRecord = false
		unless @description
			@description = "#{ require('os').hostname() }:#{ process.title } - #{ process.pid }"

	_hasErrors: ->
		return (@errors.length > 0)

	toDoc:(doc) ->
		doc = _.extend(doc or {} , _.pick(@,@opKeys))
		doc._rev = @rev if @rev?
		doc.startTime = doc.startTime.toISOString() if doc.startTime?
		doc.endTime = doc.endTime.toISOString() if doc.endTime?
		doc.hasErrors = @_hasErrors()
		return doc

	start:() ->
		@startTime = new Date()
		if @_skipDbRecord is true
			@doSync()
			return
		db.view 'sync', @syncView ,{ include_docs: true , descending: true, limit:5 }, (err, body, headers) =>
			lastSync = null
			# find the last finished sync
			if err is null
				for op in body.rows
					if op.doc.syncStatus is 'FINISHED'
						lastSync = op.doc
						break
			db.get @syncDocId,(err, body) =>
				if err is null
					if body.syncStatus != 'PENDING'
						log.error "Trying to start sync with already existing sync operation: %j", body, {}
						return
				if err?.error is "not_found"
					body = {}
				@withLastFinishedSync(body, lastSync)
				if @_hasErrors()
					log.error "Errors initalizing, terminating sync"
					@syncEnd()
					return
				@syncStatus = 'RUNNING'
				@toDoc(body)
				log.debug "Saving," , body
				db.insert body, @syncDocId , (err, body) =>
					if err is null
						log.verbose "Started SyncOperation '#{ @syncDocId }' : %j" , body, {}
						@rev = body.rev
						@doSync()
					else
						log.error "Error saving sync op '#{ @syncDocId }' in database : %j", { err: err , body: body }, {}

	withLastFinishedSync:(currentSync, lastSync)->
	doSync: ->
	syncEnd: ->
		if @_skipDbRecord is true
			return
		@syncStatus = 'FINISHED'
		@endTime = new Date()
		body = @toDoc()
		log.debug "Finalizing SyncOperation operation %j", body, {}
		db.insert body, @syncDocId , (err, body) =>
			if err is null
				log.verbose "End SyncOrders '#{ @syncDocId }' : %j" , body, {}
			else
				log.error "Error saving sync op '#{ @syncDocId }' in database : %j", { err: err , body: body }, {}

module.exports = SyncOperation
