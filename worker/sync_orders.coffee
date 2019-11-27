mws = require 'mws-js'
log = require('./log')()
_ = require 'underscore'
SyncOperation = require './sync_operation'
OrdersFetcher = require './orders_fetcher'
OrderItemsFetcher = require './order_items_fetcher'

AmazonCredentials= require('./cfg').AmazonCredentials

log.info "Starting ...."

class SyncOrders extends SyncOperation
	docKeys: [ 'amazonStatus',
						 'orders','orderItems',
						 'failedOrders', 'failedOrdersItems' ]
	opName: 'sync-orders'
	constructor:(@syncId, @description, params, opts) ->
		super(@syncId, @description)
		@amazonStatus = 'UNKNOWN'
		@orders = { processed: 0, updated:0 , created:0 , failed: 0, nochange:0 }
		@failedOrders = []
		@orderItems = { processed: 0, updated:0 , created:0 , failed: 0, nochange:0 }
		@failedOrdersItems = []
		@params = params
		@forceCheck = opts.force
		@overlap = opts.overlap
		@objSubtype = 'orders'
		@syncView = 'sync_orders_transactions'
		@client = new mws.orders.Client(AmazonCredentials)
		@retryOrderItemsFromLastSync = []

	_hasErrors: ->
		super() or (@orders.failed > 0) or (@orderItems.failed > 0)

	toDoc:(doc) ->
		doc = _.extend(super(doc),_.pick(@,@docKeys))
		doc.hasErrors = @_hasErrors()
		return doc

	withLastFinishedSync: (currentSync, lastSync)->
		if _.isEmpty(@params)
			# if params are not specified perform incremental update
			# based on lastSync
			log.info "Preforming incremental update, lastSync = ", lastSync
			if lastSync?
				if lastSync.hasErrors
					@retryOrderItemsFromLastSync = lastSync.failedOrdersItems
					if lastSync.params?.LastUpdatedAfter?
						@messages.push "Last sync had errors retrying with its LastUpdatedAfter "
						log.info "Last sync had errors retrying with its LastUpdatedAfter "
						@params = {LastUpdatedAfter : lastSync.params.LastUpdatedAfter }
					else if lastSync.params?.CreatedAfter?
						@messages.push "Last sync had errors retrying with its LastUpdatedAfter "
						log.info "Last sync had errors retrying with its LastUpdatedAfter "
						@params = {CreatedAfter: lastSync.params.CreatedAfter }
					else
						log.warn "Requested incremental update and last sync has errors but neither LastUpdatedAfter nor CreatedAfter, using startTime instead"
						@messages.push "Requested incremental update and last sync has errors but neither LastUpdatedAfter nor CreatedAfter, using startTime instead"
				if _.isEmpty(@params)
					if lastSync.startTime
						lastUpdatedAfter = new Date(lastSync.startTime)
						# overlap at least 2 minutes, with the last query
						if @overlap > 0
							lastUpdatedAfter.setTime(lastUpdatedAfter.getTime() - @overlap)
						# if lastUpdatedAfter is more recent that now - 2min amazon is returning error
						# this souldn't hapen generally :)
						if (new Date() - lastUpdatedAfter) < 121000
							@messages.push "LastUpdateAfter is more recent that now - 2min, using now - 2min instead"
							log.warn "LastUpdateAfter is more recent that now - 2min, using now - 2min instead"
							lastUpdatedAfter = new Date()
							lastUpdatedAfter.setMinutes(lastUpdatedAfter.getMinutes() - 2)
						@params = { LastUpdatedAfter : lastUpdatedAfter.toISOString() }
					else
							log.error "Requested incremental update and last sync has no startTime"
							@errors.push "Requested incremental update and last sync has no startTime"
			else
				log.error "Incremental update requested but no previous sync"
				@errors.push "Incremental update requested but no previous sync"

	doSync: () ->
		@client.getServiceStatus (status, res) =>
			if not status?
				log.error "Error getting amazon status :", res
				@errors.push "Error getting amazon status"
				@syncEnd()
				return
			@amazonStatus = status
			log.info "Status is: #{ status }"
			orderItemssFetch = new OrderItemsFetcher(@client)
			orderItemssFetch.autoStart = false
			for orderId in @retryOrderItemsFromLastSync
				log.info "Requeuing sync for order #{ orderId }"
				orderItemssFetch.queueFetch { AmazonOrderId: orderId }

			ordersFetch = new OrdersFetcher(@client, @params )
			ordersFetch.events.on 'createObject', (order) =>
				log.info "Queue update for order items of : #{order.AmazonOrderId}"
				orderItemssFetch.queueFetch { AmazonOrderId: order.AmazonOrderId }
				@orders.created++
			ordersFetch.events.on 'updateObject', (order) =>
				log.info "Queue update for order items of : #{order.AmazonOrderId}"
				orderItemssFetch.queueFetch { AmazonOrderId: order.AmazonOrderId }
				@orders.updated++
			ordersFetch.events.on 'samesameObject', (order) =>
				if @forceCheck
					log.info "Queue forced update for order items of : #{order.AmazonOrderId}"
					orderItemssFetch.queueFetch { AmazonOrderId: order.AmazonOrderId }
				@orders.nochange++
			ordersFetch.events.on 'startSyncObject', (order) =>
				@orders.processed++
			ordersFetch.events.on 'failedSyncObject', (err, errObj) =>
				@orders.failed++
				@errors.push {message: err, obj: errObj}
				@failedOrders.push errObj.AmazonOrderId
			ordersFetch.waitAsync.events.on 'end', =>
				log.info "Done with orders, sync order items now..."
				orderItemssFetch.fetch()
			ordersFetch.fetch()
			ordersFetch.initWaitAsync()

			# Order itesm statistics count
			orderItemssFetch.events.on 'createObject', (orderItem) =>
				@orderItems.created++
			orderItemssFetch.events.on 'updateObject', (orderItem) =>
				@orderItems.updated++
			orderItemssFetch.events.on 'startSyncObject', (orderItem) =>
				@orderItems.processed++
			orderItemssFetch.events.on 'samesameObject', (orderItem) =>
				@orderItems.nochange++
			orderItemssFetch.events.on 'failedSyncObject', (err, errObj) =>
				@orderItems.failed++
				@errors.push {message: err, obj: errObj}
				@failedOrdersItems.push errObj.AmazonOrderId
			orderItemssFetch.waitAsync.events.on 'end', =>
				log.info "All Done:)"
				@syncEnd()
			orderItemssFetch.initWaitAsync()

opts= require('yargs')
	.usage(
		"""
		Usage: $0 [options]
		When performing nonincremental update you MUST specify exactly one of createdAfter,lastUpdatedAfter .
		For more detailed optsion description check:
		https://images-na.ssl-images-amazon.com/images/G/01/mwsportal/doc/en_US/orders/MWSOrdersApiReference._V401547137_.pdf
		"""
	)
	.describe('createdAfter','CreatedAfter ListOrders parameter')
	.alias('a','createdAfter')
	.describe('createdBefore','CreatedBefore ListOrders parameter')
	.alias('b','createdBefore')
	.describe('lastUpdatedAfter','LastUpdatedAfter ListOrders parameter')
	.alias('u','lastUpdatedAfter')
	.describe('lastUpdatedBefore','LastUpdatedBefore ListOrders parameter')
	.alias('v','lastUpdatedBefore')
	.describe('incremental','Perform incremental update based on last synccessfull sync')
	.alias('i','incremental')
	.default('i',false)
	.boolean('i')
	.describe('overlap','Overlap for incremental update e.g : 5m(5 minutes), 40s(40 seconds)')
	.alias('overlap','o')
	.default('overlap','8m')
	.describe('force','Force recheck')
	.alias('f','force')
	.default('f',false)
	.boolean('f')
	.describe('description','Sync transaction description')
	.alias('d','description')
	.default('d',"#{ require('os').hostname() }:#{ process.title } - #{ process.pid }")
	.string('d')

params = null
argv = opts.argv

# convert overlap to miliseconds
mo = argv.overlap.match(/^(\d+)([smhd])?$/)
if not mo
	console.error 'Invalid overlap'
	opts.showHelp()
	process.exit(-1)
overlap=parseInt(mo[1])
switch mo[2]
	when 's' then overlap *= 1000
	when 'm' then overlap *= 60*1000
	when 'h' then overlap *= 60*60*1000
	when 'd' then overlap *= 34*60*60*1000
argv.overlap = overlap

if not argv.incremental
	params = {}
	params.CreatedAfter = argv.createdAfter  if argv.createdAfter?
	params.LastUpdatedAfter = argv.lastUpdatedAfter if argv.lastUpdatedAfter?
	if _.keys(params).length isnt 1
		opts.showHelp()
		process.exit(-1)
	params.CreatedBefore = argv.createdBefore if argv.createdBefore?
	params.LastUpdatedBefore = argv.lastUpdatedBefore if lastUpdatedBefore?
new SyncOrders(null,argv.description,params,argv).start()
