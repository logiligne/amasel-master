db = require('./db')
log = require('./log')()
_ = require 'underscore'

DESIGN_DOC = {
  "_id" : "_design/sync",
}

db.view 'sync', 'items_sync_documents' ,{ include_docs: true }, (err, body, headers) ->
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
