#!/usr/bin/env coffee

db = require('./db')
log = require('./log')()
_ = require 'underscore'
humanInterval = require 'human-interval'

opts= require('yargs')
	.usage(
		"""
		Usage: $0 --interval <internal> --ts-key <doc key with timestamp> design_doc/view [design_doc/view] ...


		"""
	)
options = opts
			.default("interval","3 months")
			.default("ts-key",["startTime","LastUpdateDate"])
			.default("dry-run", "no")
			.argv
argv = options._

unless argv[0]
	opts.showHelp()
	process.exit(0)

unless Array.isArray(options['ts-key'])
	options['ts-key'] = [ options['ts-key'] ]

delDate = new Date( Date.now() - humanInterval(options['interval']) )

log.info "Delete everything before: #{ delDate.toISOString() }"
log.info " views: #{ argv }"
promise = Promise.resolve(null)
for cleanView in argv
	do (cleanView) ->
		promise = promise.then ()->
			return new Promise (resolve, reject)->
				a = cleanView.split('/')
				log.info "Deleteting old documents in view: #{ cleanView }"
				# This is really buggy, if there are more than limit, new documents nothing gets deleted
				db.view a[0], a[1] ,{ include_docs: true , limit: 50000 }, (err, body, headers) ->
					if err is null
						delDocs = []
						delDocsRelated = []
						maps = {}
						lastKeyLen = 0
						for row in body.rows
							docDate = null
							if Array.isArray(row.key)
								# Transactional logic, don't delete order withyout deleting ALL of its items
								if row.key.length == 1 && lastKeyLen > 1
									delDocsRelated = delDocsRelated.concat( delDocs )
									delDocs = []
								key = row.key[0]
								lastKeyLen = row.key.length
								if maps[key]
									docDate = maps[key]
								else
									for tsKey in options['ts-key']
										if row.doc[tsKey]
											docDate = new Date( row.doc[tsKey] )
											maps[key] = docDate
											break
							else
								for tsKey in options['ts-key']
									if row.doc[tsKey]
										docDate = new Date( row.doc[tsKey] )
										break
							if docDate && (docDate.getTime()  < delDate.getTime())
								delDocs.push {_id: row.doc._id, _rev: row.doc._rev, _deleted: true}
						if delDocsRelated.length > 0
							delDocs = delDocsRelated
						if delDocs.length == 0
							log.info "No old documents to delete"
							resolve()
							return
						log.info  "Deleting #{ delDocs.length } documents: #{delDocs[0]._id} .. #{delDocs[delDocs.length-1]._id}"
						if options['dry-run'] == "no"
							db.bulk {docs: delDocs}, (err, body) ->
								if err is null
									log.info "Delete success, #{ body.length } deleted"
									resolve()
								else
									reject(err)
									log.error "Error deleting: %j %j", err, body, {}
						else
							resolve()
					else
						reject(err)
						log.error "Error while listing view %j", err, {}

promise.then ()->
	log.info("All done.")
.catch (err)->
	log.error 'Cleanup failed:', err


#
