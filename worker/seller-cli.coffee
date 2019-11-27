mws = require 'mws-js'
log = require('./log')()
util = require 'util'

AmazonCredentials=  require('./cfg').AmazonCredentials

opts= require('yargs')
	.usage(
		"""
		Usage: $0
		Perform seller related queries
		"""
	)
	.argv

client = new mws.sellers.Client(AmazonCredentials)

printResult = (res)->
	if res.error
		console.log res.error
	else if res.result
		console.log util.inspect(res.result,false,10)
	else
		console.log util.inspect(res,false,10)

client.listMarketplaceParticipations printResult
