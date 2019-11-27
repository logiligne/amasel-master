_ = require('lodash')

class GroupsMixin
	_groups:{}
	_autoGroups:{}
	_expandGroup: (group)->
		if group.indexOf('*') == group.length-1
			domain = group.slice(0, group.length-1)
			groups = _.filter(Object.keys(@_groups), (value)-> _.startsWith(value, domain))
			groups
		else
			[group]
	# Public: add a key from the primary index to named group
	#
	# group - The named group as {String}.
	# key   - The key as {String|Number}.
	#
	# Returns `undefined`.
	isInGroup: (group, key)->
		for g in @_expandGroup(group)
				return true if @_groups[g]?[key]
		false

	# Public: add a key from the primary index to named group
	#
	# group - The named group as {String}.
	# key   - The key as {String|Number}.
	#
	# Returns `undefined`.
	addToGroup: (group, key)->
		#console.log "addToGroup #{ group} , #{ key }"
		unless group of @_groups
			@_groups[group] = {}
		old = @_groups[group][key]
		@_groups[group][key] = true
		@_emitEvent('groupsChanged') unless old
		null

	# Public: remove key from named group
	#
	# group - The named groups as {String}.
	# key   - The keys as {String|Number}.
	#
	# Returns `undefined`.
	removeFromGroup: (group, key)->
		#console.log "removeFromGroup #{ group} , #{ key }"
		wasInGroup = false
		for g in @_expandGroup(group)
			wasInGroup ||= @_groups[g][key]
			delete @_groups[g][key]
		@_emitEvent('groupsChanged') if wasInGroup
		null

	# Public: remove all keys from named groups
	#
	# group - The named group as {String}.
	#
	# Returns `undefined`.
	clearGroup: (group)->
		for g in @_expandGroup(group)
			@_groups[g] = {}
		@_emitEvent('groupsChanged')
		null


	# Public: Get list of keys in a named group
	#
	# group - The named groups as {String}.
	#
	# Returns Array with the keys belinging in this group
	getKeysInGroup: (group)->
		if group of @_groups
			g = @_groups[group]
		else
			g = {}
		retVal = []
		for key, value of g
			retVal.push(key) if @has(key) and value is true
		retVal

	getNumberOfKeysInGroup: (group)->
		if group of @_groups
			g = @_groups[group]
		else
			return 0
		retVal = 0
		for key, value of g
			retVal++ if @has(key) and value is true
		retVal

	# Public: get list of existing named groups
	#		given the groups ['flags.flag1', 'flags.flag2', 'some.group', 'another']
	#		getGroups('flags.') will return ['flags.flag1', 'flags.flag2']
	# domain - The domain of the groups to return as {String|null}.
	#
	# Returns Array with the named group names mathing the domain or all groups if
	#		the domain parameter is null
	getGroups: (domain)->
		return Object.keys(@_groups) unless domain
		_.map(
			@_expandGroup(domain)
			(value)-> value.replace(domain, '')
		)

	getAutoGroups: ()->
		@_autoGroups
	setAutoGroups: (autoGroups={})->
		@_autoGroups = {}
		@addAutoGroups(autoGroups)
		null
	addAutoGroups: (autoGroups={})->
		for group, func of autoGroups
			if typeof func is 'function'
				@_autoGroups[group] = func
		@forEach (value, key)=>
			@_updateAutoGroups(key, value)
		null
	_updateAutoGroups: (key, value)->
		changed = false
		for group, func of @_autoGroups
			isInGroup = @isInGroup(group, key)
			result = func(value, key)
			unless Array.isArray(result)
				result = [ result ]
			if group.indexOf('*') == group.length-1
				groups = @_expandGroup(group)
				@removeFromGroup(group,key)
				for r in result
					if (typeof r is 'boolean') or (typeof r is 'number') or r
						group = group.replace('*', r.toString())
						@addToGroup(group, key)
				changed ||= isInGroup and result.length == 0
				changed ||= !isInGroup and result.length >= 0
			else
				for r in result
					if !!r and !isInGroup
						@addToGroup(group, key)
						changed = true
					if !r and isInGroup
						@removeFromGroup(group, key)
						changed = true
		@_emitEvent('groupsChanged') if changed
		null
	_dumpGroups:()->
		for group in @getGroups()
			console.log "#{group} :", JSON.stringify(@_groups[group])
module.exports = GroupsMixin
