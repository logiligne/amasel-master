_ = require('lodash')
BasicCollection = require('./basic-collection')
GroupsMixin = require('./groups-mixin')

class IndexedCollection extends BasicCollection
	@include(GroupsMixin)
	constructor: (cfg={})->
		@primaryIndex = cfg.primaryIndex ? 'id'
		@columnIndexes = cfg.columnIndexes ? []
		super(cfg)

	_new: (dataList)->
		new IndexedCollection({
			primaryIndex: @primaryIndex
			columnIndexes: @columnIndexes
			data: dataList
			groups: @_groups
			autoGroups: @_autoGroups
		})

	init:(cfg)->
		super(cfg)
		@indexes = {}
		@_groups = cfg.groups ? {}
		@setAutoGroups(cfg.autoGroups)
		for group, func of cfg.autoGroups ? {}
			if typeof func is 'function'
				@_autoGroups[group] = func
		for index in @columnIndexes
			@indexes[index] = {}
		unless Array.isArray(cfg.data)
			return
		for item in cfg.data
			if @primaryIndex of item
				@set(item[@primaryIndex], item)
		return @

	_updateIndexes: (key, value)->
		for index in @columnIndexes
			if index of value
				@indexes[index][value[index]] = [] unless Array.isArray(@indexes[index][value[index]])
				@indexes[index][value[index]].push(key)
		null

	_onUpdate: (key, value)->
		super(key, value)
		@_updateIndexes(key, value)
		@_updateAutoGroups(key, value)

	_onDelete: (key)->
		value = @map[key]
		super(key)
		for index in @columnIndexes
			idxToDelete = @indexes[index][value[index]].indexOf(key)
			@indexes[index][value[index]].splice(idxToDelete,1) if idxToDelete>=0
		null
	getByIndex:(index, indexKey)->
		@map[ @indexes[index][indexKey][0] ]

	getAllByIndex:(index, indexKey)->
		@map[ i ] for i in @indexes[index][indexKey]

	sort: (fields, orders={})->
		unless Array.isArray(orders)
			orders = for field in fields
				switch orders[field]
					when 'ASC', 'asc' then true
					when 'DESC', 'desc' then false
					when null, undefined then true
					else !!orders[field]
		@_new( _.sortByOrder(@map, fields, orders) )

	_filterFunctions: {
		startsWith: (value, searchExpression)-> _.startsWith(value.toString().toLowerCase(), searchExpression)
		has: (value, searchExpression)-> value.toString().toLowerCase().indexOf(searchExpression)>=0
		isTrue: (value)-> !!value
		isFalse: (value)-> !value
		equals: (value, searchExpression)-> value == searchExpression
		less: (value, searchExpression)-> value < searchExpression
		lessOrEqual: (value, searchExpression)-> value <= searchExpression
		greater: (value, searchExpression)-> value > searchExpression
		greaterOrEqual: (value, searchExpression)-> value >= searchExpression
		exists: ()-> true
	}
	###
		Example filters:
		1. [{ field: "ASIN", filters:{ startsWith: 'B4'} }]
		2. [
				{ field: "title", filters:{ has: 'ghost'} },
				{ field: "Quantity", filters:{ equals: '0'} },
			]
		3. [
				{ field: "title", filters:{ has: 'buster'} },
				'or',
				{ field: "title", filters:{ startsWith: 'ghost'} },
			]
	###
	filter: (filters=[])->
		# Helper function to execute list of filters
		execFilterList = (filterList, value)=>
			for filter in filterList
				return false unless filter.field of value
				for funcName, expression of filter.filters
					func = @_filterFunctions[funcName]
					continue unless func # just ignore invalid functions
					result = func(value[filter.field], expression)
					return false unless result
			# if no filter function rejected the value it's a match
			return true
		# Split the filter list into 'OR' chunks
		orList = [ ]
		currentList = []
		for f in filters
			if typeof f is 'string' and f.toLowerCase() == 'or'
				orList.push(currentList) if currentList.length > 0
				currentList = []
			else
				currentList.push(f)
		orList.push(currentList) if currentList.length > 0
		# Run each OR chunk, and if any matches consider the k,v a match
		filtered = []
		@forEach (v, k)->
			for filterList in orList
				if execFilterList(filterList, v)
					filtered.push(v)
					break
			null
		@_new( filtered )

module.exports = IndexedCollection
