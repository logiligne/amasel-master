mws = require 'mws-js'
log = require('./log')()
fs  = require 'fs'

AmazonCredentials =  require('./cfg').AmazonCredentials

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
	.default('type', 'ALL')
	.string('type')
	.describe('acknowledged','select reports with acknowledged status ')
	.alias('a','acknowledged')
	.boolean('acknowledged')
	.default('acknowledged', false)

argv = opts.argv

client = new mws.reports.Client(AmazonCredentials)
#console.log argv
if argv.download
	client.getReport {ReportId: argv._[0] }, (report, res)=>
		if res.responseType  == 'Error'
			log.error res.error
			return
		reportId = argv._[0]
		file = "report-#{ reportId }.txt"
		fs.writeFileSync(file, report)
		log.info "Wrote : #{ file }"
		return
else if argv.list
	param = {Acknowledged: argv.acknowledged}
	if argv.type != 'ALL'
		param['ReportTypeList'] = argv.type
		console.log param
	client.getReportList param, (reportInfoList,res)->
		log.info reportInfoList
		if reportInfoList?
			log.info "ReportId\tAcknowledged\tAvailableDate\tReportType"
			for reportInfo in reportInfoList
				log.info "#{ reportInfo.ReportId }\t#{ reportInfo.Acknowledged }\t#{ reportInfo.AvailableDate}\t#{ reportInfo.ReportType }"
			#client.updateReportAcknowledgements {ReportIdList: ids, Acknowledged: true}, (updatedReportInfoList, res)->
			#	log.info "Updated: " , updatedReportInfoList
		else
			log.info "Query returned no reports"
		if res.nextToken?
			res.getNext()
