cfg= require('./cfg')
nano = require('nano')(cfg.db.adminServerUrl)
log = require('./log')()

DB_NAME = cfg.db.database
DESIGN_DOC = {
   "_id": "_design/sync",
   "language": "javascript",
   "views": {
       "sync_orders_transactions": {
           "map": "function(doc) { if (doc.objType == 'syncOperation' && doc.objSubtype == 'orders' )\temit(doc.startTime, null) }"
       },
       "sync_orders_pending_transactions": {
           "map": "function(doc) { if (doc.objType == 'syncOperation' && doc.objSubtype == 'orders' && doc.syncStatus != 'FINISHED')\temit(doc.startTime, null) }"
       },
       "sync_items_transactions": {
           "map": "function(doc) { if (doc.objType == 'syncOperation' && doc.objSubtype == 'items' )\t emit(doc.startTime, null) }"
       },
       "sync_items_pending_transactions": {
           "map": "function(doc) { if (doc.objType == 'syncOperation' && doc.objSubtype == 'items' && doc.syncStatus != 'FINISHED')\t emit(doc.startTime, null) }"
       },
       "repricer_transactions": {
           "map": "function(doc) { if (doc.objType == 'syncOperation' && doc.objSubtype == 'price' )\t emit(doc.startTime, null) }"
       },
       "repricer_pending_transactions": {
           "map": "function(doc) { if (doc.objType == 'syncOperation' && doc.objSubtype == 'price' && doc.syncStatus != 'FINISHED')\t emit(doc.startTime, null) }"
       },
       "items_sync_documents": {
           "map": "function(doc) {\n\tif (doc.objType == 'item' || doc.objType == 'itemInfo') {\n\t\t emit(null,null);\n\t}\n}"
       },
       "items_documents_by_sku": {
           "map": "function(doc) {\n\tif (doc.objType == 'item') {\n\t\t emit(doc.SKU,null);\n\t}\n}"
       },
       "items_documents_by_asin": {
           "map": "function(doc) {\n\tif (doc.objType == 'item' || doc.objType == 'itemInfo') {\n\t\t emit(doc.ASIN,null);\n\t}\n}"
       },
       "orders_sync_documents": {
           "map": "function(doc) {\n\tif (doc.objType == 'order' || doc.objType == 'orderItem') {\n\t\t emit(null,null);\n\t}\n}"
       },
       "all_orders_by_lastupdated": {
           "map": "function(doc) { if (doc.objType == 'order')\t emit(doc.LastUpdateDate, doc.OrderStatus) }"
       },
       "pending_orders_by_lastupdated": {
           "map": "function(doc) {\n\tif (doc.objType == 'order' && doc.OrderStatus == 'Pending') {\n\t\temit(doc.LastUpdateDate, null);\n\t}\n}"
       },
       "unshipped_orders_by_lastupdated": {
           "map": "function(doc) {\n\tif (doc.objType == 'order' && (doc.OrderStatus == 'Unshipped' || doc.OrderStatus == 'PartiallyShipped')) {\n\t\temit(doc.LastUpdateDate, null);\n\t}\n}"
       },
       "shipped_orders_by_lastupdated": {
           "map": "function(doc) {\n\tif (doc.objType == 'order' && doc.OrderStatus == 'Shipped') {\n\t\temit(doc.LastUpdateDate, null);\n\t}\n}"
       },
       "canceled_orders_by_lastupdated": {
           "map": "function(doc) {\n\tif (doc.objType == 'order' && doc.OrderStatus == 'Canceled') {\n\t\temit(doc.LastUpdateDate, null);\n\t}\n}"
       },
       "unneeded_orders_with_items": {
           "map": "function (doc) {\n\t  if(doc.objType == 'order' && (doc.OrderStatus != 'Unshipped' && doc.OrderStatus != 'PartiallyShipped') ){\n\t\t  emit([doc.AmazonOrderId], 1);\n\t  }\n\t  if(doc.objType == 'orderItem' && (doc.QuantityOrdered == doc.QuantityShipped)){\n\t\t  emit([doc.AmazonOrderId, doc.ASIN ], 1);\n\t  }\n\t}"
       }
   },
   "filters": {
       "repricer_config": "function (doc) {\n\treturn (doc.objType == 'repricerConfig');\n}"
   }
}

userDoc = {
	"_id": "org.couchdb.user:" + cfg.db.user,
	"name": cfg.db.user,
	"type": "user",
	"roles": [],
	"password": cfg.db.pass
}

securityDoc = {
  "admins": {
    "names": [
      cfg.db.user
    ],
    "roles": []
  },
  "members": {
    "names": [
      "smbdy_nbdy"
    ],
    "roles": []
  }
}

# createa regular user
udb = nano.db.use('_users')
udb.insert userDoc, userDoc._id, (err, body) ->
	if err
		if err.error isnt 'conflict'
			log.error "Error while creating user %j",err, {}
			return
		else
			log.info "User already exists ", body
	else
		log.info "User crated ", body
	log.info "Creating database:", DB_NAME
	r = nano.db.create DB_NAME, (err, body) ->
		if err
			if err.error isnt 'file_exists'
				log.error "Error while creating database %j",err, {}
				return
			else
				log.info "Database already exists"
		else
			log.info "Database crated", body
		log.info "Setting database permissions..."
		db = nano.db.use(DB_NAME)
		db.insert securityDoc, '_security', (err, body) ->
			if err
				log.error "Error while setting db permissions ",err
				return
			db.head DESIGN_DOC._id , (err, body, headers) ->
				if err is null
					# set revision here, document already exists
					DESIGN_DOC._rev = headers.etag.replace(/"/g,'')
				db.insert DESIGN_DOC, DESIGN_DOC._id, (err, body) ->
					if err
						log.error "Error while creating views ", err
						console.log(err)
					else
						log.info "Views crated ", body
