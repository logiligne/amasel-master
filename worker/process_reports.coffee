mws = require 'mws-js'
log = require('./log')()
fs  = require 'fs'
csv = require 'csv'
_ = require 'underscore'
Iconv  = require('iconv').Iconv

AmazonCredentials =  require('./cfg').AmazonCredentials
db = require './db'

opts= require('yargs')
	.usage(
		"""
		Usage: $0 [options]

		"""
	)
	.describe('download','Download the report, no db synchronization')
	.alias('d','download')
	.boolean('download')
	.describe('list','List reports')
	.alias('l','list')
	.boolean('list')
	.describe('type','Report type')
	.alias('t','type')
	.default('type', '_GET_V2_SETTLEMENT_REPORT_DATA_FLAT_FILE_')
	.string('type')
	.describe('ack-status','select reports with acknowledge status [true,false]')
	.alias('s','ack-status')
	.string('ack-status')
	.describe('acknowledge','Acknowledge report after processing it')
	.alias('a','acknowledge')
	.boolean('acknowledge')
	.describe('encoding','Encoding to use for reports , default is iso-8859-1')
	.alias('e','encoding')
	.string('encoding')
	.default('encoding', 'iso-8859-1')
	.describe('number','number of reports to process')
	.alias('n','number')
	.string('number')
	.default('number', 1)
	.describe('id','Process report with id')
	.alias('i','number')
	.string('id')


argv = opts.argv

client = new mws.reports.Client(AmazonCredentials)
#console.log argv

stringToDate = (dateString)->
  d = new Date(dateString)
  if isNaN( d.getTime() )
  	return dateString
  return d

processReport = (reportId)->
	client.getReport {ReportId: reportId }, (report, res)=>
		if res.responseType  == 'Error'
			log.error res.error
			return
		iconv = new Iconv(argv.encoding,'UTF-8')
		reportUTF8 = iconv.convert(report)
		csv()
			.from(reportUTF8.toString() , {delimiter: '\t'})
			.on 'error', (error)=>
				log.error error.message, error
			.to.array (rows) =>
				stats = {}
				stats.orders = {}
				stats.numItems = 0
				stats.itemsAmount = 0.0
				stats.refundAmount = 0.0
				stats.shippingAmount = 0.0
				stats.amazonFees = 0.0
				stats.previousReserveAmountDate = null
				stats.previousReserveAmount = 0.0
				orders = stats.orders
				# remove first row, as it is column names
				for row in rows[1..]
					doc = _.object(['settlement-id', 'settlement-start-date',	'settlement-end-date',
													'deposit-date',	'total-amount',	'currency',	'transaction-type',
													'order-id',	'merchant-order-id', 'adjustment-id', 'shipment-id', 'marketplace-name',
													'shipment-fee-type',	'shipment-fee-amount', 'order-fee-type',
													'order-fee-amount',	'fulfillment-id',	'posted-date', 'order-item-code',
													'merchant-order-item-id', 'merchant-adjustment-item-id', 'sku',
													'quantity-purchased', 'price-type',	'price-amount',	'item-related-fee-type',
													'item-related-fee-amount', 'misc-fee-amount' ,'other-fee-amount',
													'other-fee-reason-description', 'direct-payment-type', 'direct-payment-amount',
													'other-amount'], row)
					if doc['transaction-type'] in ['Order', 'Adjustment', 'Refund']
						oid = doc['order-id']
						if not orders[oid]
							orders[oid] = {}
						qty = parseInt(doc['quantity-purchased'])
						if qty
							orders[oid].items = qty
							stats.numItems += qty
						pt = doc['price-type']
						if pt
							price = parseFloat(doc['price-amount'])
							if price and pt is 'Principal'
								orders[oid].price = price
								if price > 0
									stats.itemsAmount += price
								else
									stats.refundAmount += price
							if price and pt is 'Shipping'
								orders[oid].shipping = price
								if price > 0
									stats.shippingAmount += price
								else
									stats.refundAmount += price
						feeType = doc['item-related-fee-type']
						if feeType
							fee = parseFloat(doc['item-related-fee-amount'])
							if fee and feeType is 'ShippingHB'
								orders[oid].shippingHB = fee
								# positive fee amounts, go to refund
								if fee < 0
									stats.amazonFees += fee
								else
									stats.refundAmount += fee
							if fee and feeType is 'Commission'
								orders[oid].commission = fee
								# positive fee amounts, go to refund
								if fee < 0
									stats.amazonFees += fee
								else
									stats.refundAmount += fee
						if doc['posted-date']
							orders[oid].date = stringToDate(doc['posted-date'])
					else if doc['transaction-type'] is 'Subscription Fee'
						stats.subscriptionDate = stringToDate(doc['posted-date'])
						stats.subscriptionFee = parseFloat(doc['other-amount'])
					else if doc['transaction-type'] is 'Previous Reserve Amount Balance'
						stats.previousReserveAmountDate = stringToDate(doc['posted-date'])
						stats.previousReserveAmount = parseFloat(doc['other-amount'])
					else
						if doc['settlement-start-date']
							stats.startDate = stringToDate(doc['settlement-start-date'])
						if doc['settlement-end-date']
							stats.endDate = stringToDate(doc['settlement-end-date'])
						if doc['total-amount']
							stats.totalAmount = parseFloat(doc['total-amount'])
						if doc['currency']
							stats.currency = doc['currency']
				stats.objType = 'billing'
				stats.objSubtype = 'billingReport'
				db.insert stats,(err, body)->
					if err
						log.error err
						return
					log.info "Report #{reportId} done..."
					if argv.acknowledge
						client.updateReportAcknowledgements {ReportIdList: reportId, Acknowledged: true}, (updatedReportInfoList, res)->
							log.info "Update report acknowledgement: " , updatedReportInfoList


if argv.id
	log.info "Processing report: ", argv.id
	processReport argv.id
else
	options = { ReportTypeList: argv.type}
	if argv['ack-status'] and ( argv['ack-status'] in ['true', 'false'])
		options['Acknowledged'] = argv['ack-status'] == 'true'

	log.info "getReportInfo:", options
	client.getReportList options, (reportInfoList,res)->
		log.info reportInfoList
		if reportInfoList?
			unless Array.isArray reportInfoList then reportInfoList = [ reportInfoList ]
			for reportInfo in reportInfoList
				if argv.number <= 0
					break
				if argv.list
					log.info "#{ reportInfo.ReportId }\t#{ reportInfo.Acknowledged }\t#{ reportInfo.AvailableDate}\t#{ reportInfo.ReportType }"
				else
					log.info "Processing #{ reportInfo.ReportId }\t#{ reportInfo.Acknowledged }\t#{ reportInfo.AvailableDate}\t#{ reportInfo.ReportType }"
					processReport reportInfo.ReportId
				argv.number--
		else
			log.info "Query returned no reports"
		if res.nextToken?
			res.getNext()
