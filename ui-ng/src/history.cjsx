_ = require('lodash')
model =	require('db-model').get('default')

React = require('react')
HistoryFilter = require('./components/historyfilter.cjsx')
HistoryList = require('./components/historylist.cjsx')

# Page 'Repricer history' module
History = React.createClass
	# Data handling
	loadFromModel: ()->
		model.fetchProducts().then ()=>
			@setState({
				products: model.products,
				data: model.products.asList()
			})
		.catch (err)=>
			console.error err
	getData: (filter)->
		if filter? and filter.length > 0
			_newData = @state.products.filter(@state.filter = filter)
		else
			_newData = @state.products
		return _newData

	# Connect filter with it's parent component
	onFilterChange: (filter)->
		@setState
			data: @getData(@state.filter = filter).sort(@state.sortFields, @state.sortOrders).asList()

	# Connect sort with it's parent component
	onSortChange: (fields, orders)->
		@setState
			data: @getData(@state.filter).sort(@state.sortFields = fields, @state.sortOrders = orders).asList()

	# Just fetch the data when ui is ready
	componentDidMount: ()->
		@loadFromModel()
	getInitialState: ()->
		return {
			filter: [],
			products: [],
			data: [],
			sortFields: [],
			sortOrders: {}
		}
	render: ()->
		<div className="col-lg-12">
			<div className="row"><div className="col-lg-12">&nbsp;</div></div>
			<div className="row">
				<div className="col-lg-12">
					<HistoryFilter onFilterChange={@onFilterChange} />
				</div>
			</div>
			<div className="row">
				<HistoryList data={@state.data} onSortChange={@onSortChange} />
			</div>
		</div>

module.exports = History
