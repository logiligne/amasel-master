events = require "events"
mws = require 'mws-js'
log = require('./log')()
_ = require 'underscore'
db = require './db'

# Increase maxSockets for https pool
https = require 'https'
https.globalAgent.maxSockets = 50

SyncOperation = require './sync_operation'
WaitAsyncWork = require('./wait_async_work')
Item = require './sync/item'
fs = require 'fs'
csv = require 'csv'
Iconv  = require('iconv').Iconv
ProductsFetcher = require('./products_fetcher')

AmazonCredentials= require('./cfg').AmazonCredentials

log.info "Starting ...."

class SyncItems extends SyncOperation
	docKeys: [ 'reportId','reportRequestId'
							'items', 'itemsInfo',
							'reportStartedProcessingDate',
							'reportCompletedProcessingDate' ]
	opName: 'sync-items'
	pollInterval : 45000
	constructor:(@syncId, @description,opts) ->
		super(@syncId, @description)
		@items = { processed: 0, updated:0 , created:0 , failed: 0, nochange:0 }
		@itemsInfo = { processed: 0, updated:0 , created:0 , failed: 0, nochange:0 }
		@downloadOnly = opts?.download
		@preserveOld = opts?.old
		if @downloadOnly
			@_skipDbRecord = true
		@encoding = opts.encoding ? 'iso-8859-1'
		@objSubtype = 'items'
		@syncView = 'sync_items_transactions'
		@client = new mws.reports.Client(AmazonCredentials)
		@events = new events.EventEmitter()
		@waitAsync =  new WaitAsyncWork()
		@events.on 'startSyncObject', =>
			@items.processed++
		@events.on 'samesameObject', =>
			@items.nochange++
		@events.on 'createObject', =>
			@items.created++
		@events.on 'updateObject', =>
			@items.updated++
		@events.on 'failedSyncObject', =>
			@items.failed++
		@waitAsync.events.on 'end', =>
			log.info "Done with item quantity, sync items info now..."
			@doneWithItems()
		@waitAsync.attachToThrottledFetcher( @ )

	_hasErrors: ->
		super() or (@items.failed > 0)

	toDoc:(doc) ->
		doc = _.extend(super(doc),_.pick(@,@docKeys))
		doc.hasErrors = @_hasErrors()
		return doc

	withLastFinishedSync: (currentSync, lastSync)->

	doSync: () ->
		@client = new mws.reports.Client(AmazonCredentials)
		@client.requestReport {ReportType: '_GET_FLAT_FILE_OPEN_LISTINGS_DATA_', MarketplaceIdList:[AmazonCredentials.marketplaceId]}, (repReqInfo,res)=>
			@reportRequestId = repReqInfo.ReportRequestId
			log.info "Waiting for report request #{ @reportRequestId }"
			@checkIfReportIsReady (reportInfo) =>
				@reportId = reportInfo.GeneratedReportId
				log.info "Report is ready reportId=#{ @reportId }"
				@client.getReport {ReportId: @reportId }, (report, res)=>
					if res.responseType  == 'Error'
						log.error res.error
						return
					if @downloadOnly
						file = "report-#{ @reportId }.txt"
						fs.writeFileSync(file, report)
						log.info "Wrote : #{ file }"
						return
					iconv = new Iconv(@encoding,'UTF-8')
					reportUTF8 = iconv.convert(report)
					@asinsFetched = []
					csv()
						.from(reportUTF8.toString() , {delimiter: '\t'})
						.on 'error', (error)=>
							log.error error.message, error
						.to.array (rows) =>
							# remove first row, as it is column names
							for row in rows[1..]
								doc = _.object(['SKU', 'ASIN', 'Price', 'Quantity'], row)
								doc.objSource = 'amazon'
								doc.objType = 'item'
								item = new Item(doc)
								item.proxyEventsToFetcher(@)
								item.sync()
								@asinsFetched.push(doc['ASIN'])

	checkIfReportIsReady: (cb) ->
		setTimeout ( ()=>
			@client.getReportRequestList {ReportRequestIdList: @reportRequestId}, (repReqList,res)=>
				retry =  res?.responseType is 'Error' and res?.error?.Code is 'RequestThrottled'
				log.warn "Throttled " if retry
				if retry or not (repReqList.ReportProcessingStatus in [ "_CANCELLED_", "_DONE_", "_DONE_NO_DATA_" ])
					@checkIfReportIsReady cb
				else
					@reportStartedProcessingDate = repReqList.StartedProcessingDate
					@reportCompletedProcessingDate = repReqList.CompletedProcessingDate
					cb repReqList
		) , @pollInterval

	doneWithItems:->
		@asinsFetched = _.uniq(@asinsFetched)
		@client.updateReportAcknowledgements {ReportIdList: @reportId, Acknowledged: true}, (updatedReportInfoList, res)=>
			if res?.responseType is 'Error'
				log.info "Error acknowledging report #{ @reportId } - ", res?.error
			else
				log.info "Acknowledged report #{ @reportId }"
				client = new mws.products.Client(AmazonCredentials)
				params = []
				ss = 5
				for i in [0..@asinsFetched.length] by ss
					arr = @asinsFetched[i..(i+ss-1)]
					params.push arr if arr.length > 0
				productFetch = new ProductsFetcher(client,params)
				productFetch.events.on 'createObject', (product) =>
					@itemsInfo.created++
				productFetch.events.on 'updateObject', (product) =>
					@itemsInfo.updated++
				productFetch.events.on 'startSyncObject', (product) =>
					@itemsInfo.processed++
				productFetch.events.on 'samesameObject', (product) =>
					@itemsInfo.nochange++
				productFetch.events.on 'failedSyncObject', (err, errObj) =>
					@itemsInfo.failed++
					@errors.push {message: err, obj: errObj}
				productFetch.waitAsync.events.on 'end', =>
					if @preserveOld
						log.info "Not deleting old items"
						@allDone
					else
						log.info "Deleting old items"
						log.info "Fetching all Items in database..."
						db.view 'sync', 'items_documents_by_asin', {reduce: false, include_docs: true}, (err,body)=>
							@deleteOldItems(err,body)
				productFetch.initWaitAsync()
				productFetch.fetch()

	deleteOldItems: (err, body)->
		if err
			log.error "Failed to fetch item list from db:", err
			@allDone()
			return
		asinsFetchedMap = {}
		for asin in @asinsFetched
			asinsFetchedMap[asin] = true
		deleteList = []
		for doc in body.rows
			unless asinsFetchedMap[doc.key]
				deleteList.push {_id: doc.doc._id,  _rev: doc.doc._rev, _deleted: true }
		log.info "Deleting old items:", deleteList
		db.bulk { docs : deleteList }, (err, body)=>
			if err
				log.error "Failed deleting old items:", err
			log.info "Deleting old items result:", body
			@allDone()

	allDone: ->
		log.info "All Done:)"
		@syncEnd()

opts= require('yargs')
	.usage(
		"""
		Usage: $0 [options]

		"""
	)
	.describe('download','Just download the report, no db synchronization')
	.alias('D','download')
	.describe('description','Sync transaction description')
	.alias('d','description')
	.default('d',"#{ require('os').hostname() }:#{ process.title } - #{ process.pid }")
	.string('d')
	.describe('encoding','Encoding to use for reports , default is iso-8859-1')
	.alias('e','encoding')
	.string('e')
	.describe('old','Keep old items still present in the DB but not on amazon')
	.alias('o','old')

argv = opts.argv
new SyncItems(null,argv.description,argv).start()
