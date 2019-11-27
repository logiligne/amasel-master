db = require('./db')
log = require('./log')()
_ = require 'underscore'

opts= require('yargs')
	.usage(
		"""
		Usage: $0 design_doc view

		"""
	)
argv = opts.argv._

unless argv[0] and argv[1]
	opts.showHelp()
	process.exit(0)

log.info "Deletetin all documents in view: #{argv[0]}/#{argv[1]}"

db.view argv[0], argv[1] ,{ include_docs: true }, (err, body, headers) ->
	if err is null
		# set revision here, document already exists
		docs = ( _.extend({_deleted: true},row.doc ) for row in body.rows )
		db.bulk {docs: docs}, (err, body) ->
			if err is null
				log.info "Delete success, #{ body.length } deleted"
			else
				log.error "Error deleting:", err, body
	else
		log.error "Error while listing view  ", err
