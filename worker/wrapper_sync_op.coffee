log = require('./log')()
SyncOperation = require './sync_operation'
_ = require 'underscore'

class WrapperSyncOp extends SyncOperation
	docKeys: []

	constructor:(@promiseFunction, @description) ->
		super(null, @description)

	toDoc:(doc) ->
		doc = _.extend(super(doc),_.pick(@,@docKeys))
		doc.hasErrors = @_hasErrors()
		return doc

	doSync: ()->
		new Promise(@promiseFunction).then(
			(res)=> @onComplete(null, res)
			(err)=> @onComplete(err, null)
		).catch((e)-> onComplete(e))

	onComplete: (err, res)->
		if err
			errArray = if Array.isArray(err) then err else [ err ]
			log.error 'Error: %j', err[0], {}
			for key in @docKeys
				for singleRes in errArray
					if key of singleRes and singleRes[key]?
						@[key] = singleRes[key]
		if res
			resArray = if Array.isArray(res) then res else [ res ]
			for key in @docKeys
				for singleRes in resArray
					if key of singleRes and singleRes[key]?
						@[key] = singleRes[key]
		[logOut, logErr] = require('./log')({getLoggedInMemory:true})
		if logErr
			@errors = logErr
		if logOut
			@messages = logOut
		@syncEnd()

module.exports = WrapperSyncOp
