cfg = require './config'

if cfg.db.user
	cred = cfg.db.user
	if cfg.db.pass
		cred += ':' + cfg.db.pass
	cred += '@'
else
	cred = ''

if cfg.db.adminUser
	adminCred = cfg.db.adminUser
	if cfg.db.adminPass
		adminCred += ':' + cfg.db.adminPass
	adminCred += '@'
else
	adminCred = ''

cfg.db.serverUrl = (cfg.db.proto ? 'http') + '://' + cred + cfg.db.server + '/'
cfg.db.url = cfg.db.serverUrl + cfg.db.database
cfg.db.adminServerUrl = (cfg.db.proto ? 'http') + '://' + adminCred + cfg.db.server + '/'
cfg.db.adminUrl = cfg.db.adminServerUrl + cfg.db.database
module.exports = cfg
