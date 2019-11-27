mws = require 'mws-js'
log = require('./log')()
util = require 'util'
fs = require 'fs'
WaitForFeed = require './wait_for_feed'

AmazonCredentials=  require('./cfg').AmazonCredentials

opts= require('yargs')
	.usage(
		"""
		Usage: $0 [options] product_id [product_id ...]
		Perform different product queries
		"""
	)
	.describe('query','Query type one of Products API queries, e.g. "GetLowestOfferListingsForSKU" ')
	.alias('q','query')
	.default('query','getMatchingProductForId')
	.describe('id-type','type of id : ASIN, GCID, SellerSKU, UPC, EAN, ISBN, or JAN ')
	.alias('t','id-type')
	.default('id-type','SellerSKU')
	.alias('f','file')
	.demand('_')
	.argv

client = new mws.products.Client(AmazonCredentials)
feedClient = new mws.feeds.Client(AmazonCredentials)
#client.getMatchingProductForId 'SellerSKU','28e xxx', (res)->

printResult = (res)->
  if res.error
    console.log 'Error:',res.error
  else if res.result
    console.log util.inspect(res.result,false,10)
  else
    console.log util.inspect(res,false,10)

setPriceForSKU = (args) ->
	items = []
	for arg in args
		s = arg.match(/([^=]+)=(.*)/)
		if s[1] && s[2]
		  items.push({'SKU': s[1],'StandardPrice': s[2]})
	xmlFeeds = new mws.feeds.XMLFeeds(AmazonCredentials)
	feed = xmlFeeds.productPricing(items)
	console.log feed
	#feedClient.on 'request', (req)->
	#  console.log (req)
	feedClient.submitFeed '_POST_PRODUCT_PRICING_DATA_', feed, null, false, (res) ->
		if res?.responseType is 'Error'
			console.error('error:', res)
			return
		feedId = res.result.FeedSubmissionInfo.FeedSubmissionId
		console.log "Submitted feed #{ feedId }"
		waitFeed = new WaitForFeed feedClient, feedId, (result, error)=>
			if error
				console.error error
			else
				console.log result
		waitFeed.events.on 'end', =>
			console.log "Done."
		waitFeed.fetch()


opts.query = opts.query.charAt(0).toLowerCase() + opts.query.slice(1)
if opts.file
	lines = ( line.trim().replace(/^0+/,'') for line in fs.readFileSync(opts.file).toString().split('\n') when !line.match(/^\s*$/) )
	while lines.length
		ids = lines.splice(0,5)
		client.getMatchingProductForId 'UPC', ids , (res)->
			results = if Array.isArray(res.result) then res.result else [res.result]
			for result in results
				id = result['@']['Id']
				if result['Error']
					if result['Error']['Code'] is 'InvalidParameterValue'
						console.log "#{id},,,",JSON.stringify( result['Error'] )
					else
						console.log "#{id},,,",JSON.stringify( result['Error'] )
				else
					products = if Array.isArray(result['Products']) then result['Products'] else [ result['Products'] ]
					asins = (p['Product']['Identifiers']['MarketplaceASIN']['ASIN'] for p in products).join('|')
					titles = ("'" + p['Product']['AttributeSets']['ns2:ItemAttributes']['ns2:Title'] + "'" for p in products).join('|')
					console.log "#{id},", asins,",", titles, ","
else if opts.query == 'getMatchingProductForId'
	client[opts.query] opts['id-type'], opts._ , printResult
else if opts.query == 'getCompetitivePricingForSKU'
	client[opts.query] opts._ , printResult
else if opts.query == 'getCompetitivePricingForASIN'
	client[opts.query] opts._ , printResult
else if opts.query == 'getLowestOfferListingsForSKU'
	client[opts.query] opts._, null, false, printResult
else if opts.query == 'getLowestOfferListingsForASIN'
	client[opts.query] opts._, null, printResult
else if opts.query == 'getMyPriceForSKU'
	client[opts.query] opts._, null, printResult
else if opts.query == 'getMyPriceForASIN'
	client[opts.query] opts._, null, printResult
else if opts.query == 'setPriceForSKU'
	setPriceForSKU opts._
else if opts.query == 'getFeedSubmissionResult'
	feedClient[opts.query] opts._, printResult
else
	console.log "Unknown query: #{opts.query}"
