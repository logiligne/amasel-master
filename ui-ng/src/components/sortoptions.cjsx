_ = require('lodash')
React = require('react')

# Create 'Sort by' element
#
# @param [onChange] Callback(field, direction)
# @param [config] Array of plain objects
#
SortOptions = React.createClass
	getInitialState: ()->
		return {
			onChange: @props.onChange
			direction: 1,
			selected: null
		}
	onClick: (event)->
		dirs = ['DESC', 'ASC']
		if event.target.dataset.role and event.target.dataset.role == 'sort'
			@state.direction = Number(!@state.direction)

			orders = {}
			orders[event.target.name] = dirs[@state.direction]

			@state.selected = event.target.name
			@state.onChange([event.target.name], orders)

	_getDirArrow: (dir)->
		arrows = ['fa fa-long-arrow-up', 'fa fa-long-arrow-down']
		return <span className={arrows[dir]}></span>

	render: ()->
		items = []
		if @props.config?
			items = @props.config.map (item)->
				label = _.values(item)[0]
				field = _.keys(item)[0]
				<li key={Math.random()} role="presentation" className="selected">
					<a href="javascript: void(0);" data-role="sort" name={field} tabindex="-1">{label}</a>
				</li>

		label = 'Sort by'
		arrow = ''

		if @state.selected?
			label = label + ': ' + @state.selected
			arrow = @_getDirArrow(@state.direction)

		<div className="dropdown pull-right">
			<button className="btn btn-default dropdown-toggle" type="button" id="dropdownMenu1"
				data-toggle="dropdown" aria-expanded="true">
			{arrow} {label} &nbsp;
			</button>
			<ul className="dropdown-menu"
					role="menu" aria-labelledby="dropdownMenu1" onClick={@onClick}>{items}</ul>
		</div>

module.exports = SortOptions
