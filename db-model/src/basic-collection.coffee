_ = require('lodash')
require('./mixin')
EventEmitter = require('events').EventEmitter

class BasicCollection
	constructor: (cfg)->
		@init(cfg)
		@_events = {}

	init:(cfg)->
		@map = {}
		@_keys = []
		return @

	refEvents: (tag='default')->
		unless tag of @_events
			@_events[tag] = {ee: new EventEmitter(), refs:0}
		@_events[tag].refs++
		@_events[tag].ee

	unrefEvents: (tag='default')->
		unless tag of @_events
			return
		@_events[tag].refs--
		if @_events[tag].refs == 0
			delete @_events[tag]

	_emitEvent: (event, args...)->
		for k,v of @_events
			v.ee.emit(event, args...)
	_onUpdate: (key, value)->
		@_emitEvent('changed', key, value)
	_onDelete: (key)->
		@_emitEvent('changed', key, null)

	forEach: (cb)->
		if cb?
			for key in @_keys
				cb( @map[key], key )

	length: ()->
		@_keys.length

	keys: ()->
		@_keys.slice(0)

	has: (key)->
		key of @map

	get:(key)->
		@map[key]

	getAtPosition:(idx)->
		if 0 <= idx < @_keys.length
			@map[@_keys[idx]]
		else
			null

	set:(key, value)->
		unless key of @map
			@_keys.push key
		@map[key] = value
		@_onUpdate(key, value)

	update: (key, value, customizer)->
		if !(key of @map) or !@map[key]?
			return @set(key, value)
		_.assign(@map[key], value, customizer)
		@_onUpdate(key, value)

	merge: (key, value, customizer)->
		if !(key of @map) or !@map[key]?
			return @set(key, value)
		_.merge(@map[key], value, customizer)
		@_onUpdate(key, value)

	delete: (key)->
		@_onDelete(key)
		if !(key of @map)
			return
		delete @map[key]
		_.pull(@_keys, key)
		null

	asList: ()->
		for key in @_keys
			@map[key]

module.exports = BasicCollection
