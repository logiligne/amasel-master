_ = require('lodash')
React = require('react')
ReactBootstrap = require('react-bootstrap')
Input = ReactBootstrap.Input

### Example of config file
	[
		{
			role: 		'filter_func'
			name: 		'input_name'
			field: 		'storage_field'
			source: 	'another_field_as_value_source'
			relation: 	'@todo'
		}
	]
###
BaseFilter =
	filterHandler: false
	filterTimeout: 100

	handleFilterEvents: (event)->
		clearTimeout @filterHandler

		triggerElements = ['checkbox', 'text']
		# fire external call only when specific events occur
		if event.target.type in triggerElements
			filterValues = @state.getValues()
			console.log filterValues
			filter = []

			_filter = _.values(filterValues)
			if _filter.length > 0

				isBoolSaved = false
				boolOperator = ''

				for conf, index in @state.filterConfig
					# detect and add logical operator only if the next item exists and it is not boolean
					if _.isString(conf)
						boolOperator = conf
						isBoolSaved = true
						continue

					# just skip it of there is no data for this config item
					if not filterValues[conf.name]?
						continue

					# skip it if the filter value comes from another field and that field is empty
					if conf.role and not filterValues[conf.source]?
						continue

					# Check for any booleans left
					if isBoolSaved
						filter.push(boolOperator)
						isBoolSaved = false

					_obj = {field: conf.field, filters: {}}
					_obj['filters'][conf.role] = if filterValues[conf.source]? then filterValues[conf.source] else filterValues[conf.name]
					filter.push(_obj)

			# trigger the filter
			delayedCall = ()=>
				@state.onFilterChange filter
			@filterHandler = setTimeout delayedCall, @filterTimeout
	getInitialState: ()->
		return {
			getValues: @props.getValuesMethod,
			onFilterChange: @props.onFilterChange,
			filterConfig: @props.config
		}
	onSubmit: ()->
		return false
	render: ()->
		<form onClick={@handleFilterEvents} onKeyUp={@handleFilterEvents} onSubmit={@onSubmit}>
			<Input wrapperClassName='wrapper'>
				{@props.children}
			</Input>
		</form>

module.exports = BaseFilter
