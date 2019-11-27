#!/usr/bin/env coffee
db_cfg = require('./cfg').db
nano = require('nano')(db_cfg) 
#console.log db_cfg
module.exports = nano

# test the db connection if invoked from command line
if require.main is module
	nano.info (err, body)->
		console.log body
		console.log "Error:", err