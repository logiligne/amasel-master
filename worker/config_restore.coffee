#!/usr/bin/env coffee

cfg  = require('./cfg')
nano = require('nano')(cfg.db.adminServerUrl)
log  = require('./log')()
fs   = require('fs')
argv = require('yargs')
			.demand(1)
			.default('db', cfg.db.database)
			.argv

bakFile = argv._[0]
console.info "Using backup file #{bakFile}"
configList = JSON.parse( fs.readFileSync(bakFile) )

db = nano.db.use(argv.db)
db.view 'app', 'config' , { include_docs: true }, (err, body, headers) ->
	if err is null
		# set revision here, document already exists
		revs = {}
		for row in body.rows
			revs[row.doc._id] = row.doc._rev
		for doc in configList
			if doc._id of revs
				doc._rev = revs[doc._id]
			else
				delete doc._rev
		db.bulk {docs: configList}, (err, body) ->
			if err is null
				log.info "Successfully restored config"
			else
				log.error "Error writing to db:", err, body
	else
		log.error "Error while listing view  ", err
