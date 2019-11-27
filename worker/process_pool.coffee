log = require('./log')()
path = require 'path'
_ = require 'underscore'
spawn = require('child_process').spawn

class ProcessPool
	cp: require('child_process')
	constructor:(@workDirBase, @envBase) ->
		@pool = {}
		@envBase ?= {}
		
	_addToPool:(name, child, allowMultiple)->
		if allowMultiple
			@pool[name] ?= []
			@pool[name].push( child )
		else
			@pool[name] = child
	
	_finished:(name, child, allowMultiple)->
		if allowMultiple
			i = @pool[name].indexOf child
			@pool[name].splice i, 1
		else
			delete @pool[name]
		
	_spawn: (allowMultiple, name, command, args, options) ->
		if not allowMultiple and @pool[name]?
			return false
		options ?= {}
		options.cwd ?= @workDirBase
		if args
			args = [ args ] if not (args instanceof Array)
		if options.relCwd? and  @workDirBase?
			options.cwd = path.join @workDirBase, options.relCwd
		if not options.env
			options.env = _.extend(_.clone(process.env), @envBase)
		else
			options.env = _.extend(_.clone(process.env), _.defaults(options.env, @envBase))
		#options.stdio = 'ignore'
		options.stdio = 'inherit'
		child = spawn command, args, options
		#log.info "child", child
		do (child,name) =>
			if options.timeout? and options.timeout>0
				tid = setTimeout ( =>
					log.info "Send SIGTERM to #{name } after #{ options.timeout} ms";
					child.kill('SIGTERM')
				), options.timeout
			child.on 'exit', (code) =>
				log.info "#{name } exited with code #{ code }";
				if tid?
					clearTimeout(tid)
				@_finished name, child, allowMultiple
		@_addToPool name, child, allowMultiple
		return true
	
	spawn: (name, command, args, options)->
		@_spawn(true, name, command, args, options)

	spawnSingleton: (name, command, args, options)->
		@_spawn(false, name, command, args, options)
		
		
module.exports = ProcessPool
# run simple test
if require.main is module
	# test basic spawn
	a = [ [ "echo" , "aaa"], [ "echo" , "bbb"], [ "echo" , "ccc"] ]
	pp = new ProcessPool()
	for c in a
		#r = pp.spawnSingleton("echo",c[0],c[1])
		r = pp.spawn("echo",c[0],c[1])
		log.info "Spawned #{c[0]} result #{r}"
	# test timeout
	a = [ [ "sleep" , "5"], ["sleep", "3"] ]
	pp = new ProcessPool()
	for c in a
		r = pp.spawn("sleep",c[0],c[1],{timeout:4000})
		log.info "Spawned #{c[0]} result #{r}"

	process.on 'exit', ()->
		log.info "Exiting. Process pool:", pp.pool
