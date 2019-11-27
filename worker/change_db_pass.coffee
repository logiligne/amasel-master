cfg= require('./cfg')
nano = require('nano')(cfg.db.adminServerUrl)
log = require('./log')()

argv = require('yargs')
			.demand(1)
			.default('user', cfg.db.user)
			.argv

newPass = argv._[0]

# createa regular user
udb = nano.db.use('_users')
userId ="org.couchdb.user:" + cfg.db.user
udb.get userId, (err, body) ->
	if err
			log.error "Cannot find user: #{cfg.db.user}", err
			return
	body.password = newPass
	udb.insert body, userId, (err, body) ->
		if err
			log.error "Error while saving password ",err
			return
		log.info "Password changes successfully ", body
