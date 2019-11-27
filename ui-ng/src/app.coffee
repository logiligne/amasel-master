# Initialise the default db model singleton
dbUrl = window.location.protocol + '//' + window.location.host + window.location.pathname;

if dbUrl[dbUrl.length-1] != '/'
	dbUrl += '/'
dbUrl += 'api/'

console.log 'DB is at:', dbUrl
require('db-model').get('default',dbUrl)


Application = require('./app.cjsx')
app = new Application
app.start()
