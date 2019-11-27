winston  = require 'winston'

LOGFILE_OPTS =
	maxsize: 10485760 # 10MB
	maxFiles: 3
	json: false
	timestamp: true
	level: 'verbose'

LEVELS =
	silly: 0
	debug: 1
	verbose: 2
	info: 3
	warn: 4
	error: 5

COLORS =
	silly: 'magenta'
	debug: 'blue'
	verbose: 'cyan'
	info: 'green'
	warn: 'yellow',
	error: 'red'

getLogFilename = ()->
	# deduce logname from scriptname
	path = require 'path'
	fileName = path.basename process.argv[1]
	fileName = fileName.replace(/\.[^\.]*$/,'.log')
	#console.log "Using logname : '#{ process.cwd() }  | #{ fileName  }'"
	return fileName

getBgLogFilename = ()->
	if not process.env.AMASEL_BG_LOG?
		return null
	#console.log "Env logname : '#{ process.env.AMASEL_BG_LOG }'"
	if process.env.AMASEL_BG_LOG.length > 0
		return process.env.AMASEL_BG_LOG
	getLogFilename()

logger = null
memWriteOutput = null
memErrorOutput = null

createLogger = (opts)->
	if opts?.getLoggedInMemory is true
		return [ memWriteOutput, memErrorOutput ]
	if logger?
		if opts?.addFile
			if opts?.addFile is true
				LOGFILE_OPTS.filename=getLogFilename()
			else
				LOGFILE_OPTS.filename=opts?.addFile
			logger.add(winston.transports.File, LOGFILE_OPTS);
		if opts?.removeConsole
			logger.remove(winston.transports.Console)
		return logger
	transports = []
	fileName = getBgLogFilename()
	if not fileName?
		# stupid buggy console logger in 0.9.0, needs
		consoleLogger = new (winston.transports.Console)({
			showLevel:false,
			timestamp: false,
			level: 'info',
			formatter: (o) -> o.message
			})
		transports.push consoleLogger
	if fileName?
		LOGFILE_OPTS.filename = fileName
		LOGFILE_OPTS.json = false
		LOGFILE_OPTS.timestamp = true
		transports.push new (winston.transports.File)(LOGFILE_OPTS)
	if opts?.memory
		memoryOpts = {}
		if typeof opts.memory is 'object'
			memoryOpts = opts.memory
		memoryOpts.level = 'verbose'
		memLogger = new (winston.transports.Memory)(memoryOpts)
		transports.push memLogger
		memWriteOutput = memLogger.writeOutput
		memErrorOutput = memLogger.errorOutput
	logger = new winston.Logger
		transports: transports
	logger.cli()
	logger.setLevels LEVELS
	winston.config.addColors COLORS
	logger.padLevels = false
	logger.level = 'info'
	return logger

module.exports = createLogger
