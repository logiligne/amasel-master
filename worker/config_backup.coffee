#!/usr/bin/env coffee

cfg  = require('./cfg')
nano = require('nano')(cfg.db.adminServerUrl)
log  = require('./log')()
fs   = require('fs')
argv = require('yargs')
    .default('db', cfg.db.database)
    .argv

db = nano.db.use(argv.db)
db.view 'app', 'config' , { include_docs: true }, (err, body, headers) ->
	if err is null
		# set revision here, document already exists
		bakFile = 'backup-' + argv.db + '-' + new Date().toISOString() + '.json'
		doc =  (row.doc for row in body.rows)
		fs.writeFileSync(bakFile, JSON.stringify(doc,null, 2) )
		log.info "#{bakFile} written successfully"
	else
		log.error "Error while listing view  ", err
