mws = require 'mws-js'
log = require('./log')({memory:{}})
util = require 'util'
Table = require 'cli-table'

# Increase maxSockets for https pool
https = require 'https'
https.globalAgent.maxSockets = 50

RepricerConfig = require './repricer_config'
RepricerFetcher = require './repricer_fetcher'
RepricerStrategy = require './repricer_strategy'
RepricerSetPrices = require './repricer_set_prices'
WrapperSyncOp     =  require './wrapper_sync_op'

AmazonCredentials= require('./cfg').AmazonCredentials

class RepriceSyncOp extends WrapperSyncOp
	docKeys:[		'command',
							'newPrices' , 'deltaPrices', 'skippedRepricing',
							'myPrices', 'myPricesMissing'
							'lowestOffers', 'lowestOffersAll',
							'lowestOffersMissing',
							'myPricesCalculated', 'lowestOfferCalculated',
							'setPricesResult',
							'setPricesResultRaw',
							'setPricesError'
					]
	opName: 'reprice-tool'
	constructor:(@promiseFunction, opts) ->
		super(@promiseFunction, opts.description)
		@objSubtype = 'price'
		@objSource = opts.source ? 'cli'
		@syncView = 'repricer_transactions'
		@command = opts.command ? 'unknown'

opts= require('yargs')
	.usage(
		"""
		Usage: $0 [command] <options> ARGS
		Perform repricing related queries
		"""
	)
	.command('show-config', 'Show current repricer config')
	.command('my-prices', 'Print my prices for SKUs')
	.command('lowest-offers', 'Print lowest offer for SKUs')
	.demand(1)
	.boolean('lo-all')
	.describe('lo-all', 'Print all lowest offers instead of first match')
	.boolean('sync')
	.describe('sync', 'Run as sync transaction')
	.describe('description','Sync transaction description')
	.alias('description','d')
	.string('description')
	.describe('source','Sync transaction source field')
	.string('source')
	.describe('background','Run as background job')
	.boolean('background')

argv=opts.argv

commandFunction = ()-> log.error 'Invalid command'
argv.command = argv._[0].toLowerCase()
# Parse skus settings from command line
skus={}
for entry in  argv._.slice(1)
	[sku, arg] = (arg.trim() for arg in entry.split('='))
	if arg and arg.indexOf(':') >= 0
		arglist = (a.trim() for a in arg.split(','))
		value = {}
		for kvEntry in arglist
			[k, v] = (kvarg.trim() for kvarg in kvEntry.split(':'))
			v=true if v == 'true'
			v=false if v == 'false'
			value[k] = v
		skus[sku] = value
	else
		skus[sku] = arg

printTable = (header, fields, dataList...)->
	table = new Table({ head: header });
	for data in dataList
		if Array.isArray(data)
			for row,idx in data
				tablerow = []
				for field in fields
					if typeof field is 'function'
						tablerow.push field(idx,row)
					else if field is 'key' or field is '@'
						tablerow.push idx
					else
						tablerow.push row[field]
				table.push tablerow
		else
			for key, valueOrArr of data
				if Array.isArray(valueOrArr)
					values = valueOrArr
				else
					values = [valueOrArr]
				for value in values
					tablerow = []
					for field in fields
						if typeof field is 'function'
							tablerow.push field(key,value)
						else if field is 'key' or field is '@'
							tablerow.push key
						else if field is '.'
							tablerow.push value
						else
							tablerow.push value[field]
					table.push tablerow
	log.info table.toString() unless argv.background

# Define commands
if argv.command == 'show-config'
	commandFunction = (cfg)->
		new Promise (resolve, reject)->
			printTable(
				['SKU', 'Min Price', 'Max Price', 'UnderLowest'],
				[
					"SKU",
					(k,v)-> v.config.minPrice ? "",
					(k,v)-> v.config.maxPrice ? "",
					(k,v)-> v.config.underLowest ? ""
				]
				cfg.items
			)
			resolve()

if argv.command == 'my-prices'
	commandFunction = (cfg)->
		new Promise (resolve, reject) ->
			client = new mws.products.Client(AmazonCredentials)
			fetcher = new RepricerFetcher(cfg, client)
			fetcher.fetchMyPrices().then(
				(res)->
					printTable(
						['SKU', 'Landed price', 'Listing price', 'Shipping'],
						['@'  , 'landedPrice',  'listingPrice',  'shippingPrice'],
						fetcher.myPrices
					)
					resolve(fetcher)
				(err)->
					log.error 'Error while fetching prices %j', err, {}
					reject([err, fetcher])
			).catch((e)-> log.error 'my-prices: %j',e,{}; reject([e, fetcher]))

if argv.command == 'lowest-offers'
	commandFunction = (cfg)->
		new Promise (resolve, reject) ->
			client = new mws.products.Client(AmazonCredentials)
			fetcher = new RepricerFetcher(cfg, client)
			fetcher.fetchLowestOffers().then(
				(res)->
					printTable(
						['SKU', 'Landed price', 'Listing price', 'Shipping'],
						['@'  , 'landedPrice',  'listingPrice',  'shippingPrice'],
						if argv['lo-all'] then fetcher.lowestOffersAll else fetcher.lowestOffers
					)
					resolve(fetcher)
				(err)->
					log.error 'Error while fetching prices %j', err, {}
					reject([err, fetcher])
			).catch((e)-> log.error 'lowest-offers: %j',e,{}; reject([e, fetcher]))

if argv.command == 'set-prices'
	commandFunction = (cfg)->
		new Promise (resolve, reject) ->
			newPrices = []
			for sku,arg of skus
				newPrice=parseFloat(arg)
				unless newPrice
					log.warn "'#{ arg }' is not a valid price for '#{sku}'"
					continue
				newPrices.push({'SKU': sku,'StandardPrice': Number(newPrice).toFixed(2)})
			unless newPrices.length
				log.error 'No valid prices to set'
				return
			log.info 'Sending new prices:'
			printTable(
				['SKU', 'New price'],
				['SKU'  , 'StandardPrice'],
				newPrices
			)
			priceSetter = new RepricerSetPrices(newPrices)
			priceSetter.setPrices().then(
				(res)->
					printTable(
						['DocumentTransactionID', 'StatusCode',
							'MessagesProcessed', 'MessagesSuccessful',
							'MessagesWithError','MessagesWithWarning'],
						['DocumentTransactionID', 'StatusCode',
							(k,v)-> v?.ProcessingSummary?.MessagesProcessed
							(k,v)-> v?.ProcessingSummary?.MessagesSuccessful
							(k,v)-> v?.ProcessingSummary?.MessagesWithError
							(k,v)-> v?.ProcessingSummary?.MessagesWithWarning
						],
						[ res.setPricesResult ]
					)
					resolve([res, priceSetter])
				(err)->
					log.error 'Error while setting prices %j', err, {}
					reject([err,priceSetter])
			).catch((e)-> log.error 'RepricerSetPrices %j',e, {}; reject([e,priceSetter]))

if argv.command == 'reprice'
	commandFunction = (cfg)->
		new Promise (resolve, reject) ->
			client = new mws.products.Client(AmazonCredentials)
			fetcher = new RepricerFetcher(cfg, client)
			fetcher.fetch().then(
				(res)->
					printTable(
						['SKU', 'My price', 'Lowest offer'],
						['@',   'landedPrice', (k,v)-> fetcher.lowestOffers[k]?.landedPrice ],
						fetcher.myPrices
					)

					repriceStrategy = new RepricerStrategy(cfg ,fetcher.myPrices, fetcher.lowestOffers)
					repriceStrategy.repriceItemsDefault()
					unless repriceStrategy.newPrices.length
						log.info 'No need for repricing or not possible. Reasons: '
						missingPrices = {}
						for sku, f of fetcher.myPricesMissing
							missingPrices[sku] = if typeof f == 'string' then f else 'Failed to get my price'
						printTable(
							['SKU', 'Reason'],
							['@',   '.'],
							repriceStrategy.skippedRepricing,
							missingPrices
						)
						resolve([fetcher, repriceStrategy])
						return
					log.info 'Setting new prices'
					printTable(
						['SKU', 'New price', 'Delta'],
						['SKU', 'StandardPrice', (k,v)-> repriceStrategy.deltaPrices[v.SKU] ],
						repriceStrategy.newPrices
					)

					priceSetter = new RepricerSetPrices(repriceStrategy.newPrices)
					priceSetter.setPrices().then(
						(res)->
							printTable(
								['DocumentTransactionID', 'StatusCode',
									'MessagesProcessed', 'MessagesSuccessful',
									'MessagesWithError','MessagesWithWarning'],
								['DocumentTransactionID', 'StatusCode',
									(k,v)-> v?.ProcessingSummary?.MessagesProcessed
									(k,v)-> v?.ProcessingSummary?.MessagesSuccessful
									(k,v)-> v?.ProcessingSummary?.MessagesWithError
									(k,v)-> v?.ProcessingSummary?.MessagesWithWarning
								],
								[ res.setPricesResult ]
							)
							resolve([fetcher, repriceStrategy, priceSetter, res])
						(err)->
							log.error 'Error while setting prices %j', err, {}
							reject([err, repriceStrategy, priceSetter])
					).catch((e)-> log.error 'RepricerSetPrices %j',e, {}; reject([err, repriceStrategy, priceSetter]))
				(err)->
					log.error 'RepricerFetcher %j',err, {}
					reject([err, fetcher])
			).catch((e)-> log.error 'RepricerFetcher %j',e, {}; reject([e, fetcher]))

main = (resolve, reject)->
	config = new RepricerConfig()
	if Object.keys(skus).length
		configLoaded = config.fromObject(skus)
	else
		configLoaded = config.loadFromDb()
	configLoaded.then(
		(cfg) ->
			commandFunction(cfg).then(resolve, reject)
		(err) ->
			log.error 'Failed to load config %j', err, {}
			reject(err)
	).catch((e)-> log.error 'main: %j',e, {}; reject(e))
if argv.sync
	new  RepriceSyncOp(main, argv).start()
else
	main(
		()->
		(err)->
			console.error err
			console.error err.stack if err.stack
	)
