path = require 'path'
log  = require('./log')()
cronJob = require('cron').CronJob
ProcessPool = require './process_pool'
dbCfg = require('./cfg').db


toolsDir = path.normalize __dirname
workDir =  path.normalize path.join(__dirname, '..', 'logs')
instanceName = path.basename(path.dirname(toolsDir))

console.log "Amasel syncer starting ..."
console.log "Workdir : #{ workDir }"

try
	require('fs').mkdirSync(workDir)
catch e


procPool = new ProcessPool(workDir,{AMASEL_BG_LOG:''})

syncOrders = ()->
		sync_orders = path.join toolsDir, 'sync_orders.coffee'
		result = procPool.spawnSingleton "sync_orders", "coffee", [ sync_orders , '-i'], { timeout: 4*60*1000 }
		log.info "Started sync-orders , result : #{ result }"

syncItems = ()->
		sync_items = path.join toolsDir, 'sync_items.coffee'
		result = procPool.spawnSingleton "sync_items","coffee",[ sync_items ], { timeout: 110*60*1000 }
		log.info "Started sync-items , result : #{ result }"

processReports = ()->
		process_reports = path.join toolsDir, 'process_reports.coffee'
		result = procPool.spawnSingleton "process_reports","coffee",[ process_reports , '-n', '1', '-s', 'false', '-a' ], { timeout: 20*60*1000 }
		log.info "Started process_reports , result : #{ result }"

repriceItems = ()->
		reprice_items = path.join toolsDir, 'repricer-tool.coffee'
		result = procPool.spawnSingleton "repricer-tool","coffee",[ reprice_items, 'reprice', '--sync', '--background'],{ timeout: 30*60*1000 }
		log.info "Started repricer-tool , result : #{ result }"

repriceCleanup = ()->
		reprice_cleanup = path.join toolsDir, 'delete_old_data.coffee'
		result = procPool.spawnSingleton "delete_old_data","coffee",[ reprice_cleanup, 'sync/repricer_transactions', 'sync/unneeded_orders_with_items', 'sync/sync_items_transactions', 'sync/sync_orders_transactions'],{ timeout: 15*60*1000 }
		log.info "Started delete_old_data, result : #{ result }"

dbBackup = ()->
		args = [ '--gzip', '--buckets', '100', 'dump', dbCfg.adminUrl , '/backup/' + instanceName ]
		log.info "Running dbBackup: couchtool #{ args }"
		result = procPool.spawnSingleton "db_backup","couchtool",args ,{ timeout: 60*60*1000 }
		log.info "Started dbBackup, result : #{ result }"


# Visual http://crontab.guru/
# Run syncOrders every 5 minutes
orderJob = new cronJob('0 */5 * * * *', syncOrders ,null , true )
# Run syncItems every 2 hours
itemsJob = new cronJob('0 0 */2 * * *', syncItems ,null , true )
# Run processReports every 6 hours
# reportsJob = new cronJob('0 0 */6 * * *', processReports ,null , true )
# Run repriceItems every 15 min
repricerJob = new cronJob('0 */15 * * * *', repriceItems ,null , true )
# Run repricerCleanupJob 1:34 every day
repricerCleanupJob = new cronJob('0 34 01 * * *', repriceCleanup ,null , true )
# Run repricerCleanupJob every hour
# dbBackupJob = new cronJob('0 34 02 * * *', dbBackup ,null , true )
