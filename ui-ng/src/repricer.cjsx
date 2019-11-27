_ = require('lodash')
React = require('react')
RepricerFilter = require('./components/repricerfilter.cjsx')
RepricerItem = require('./components/repriceritem.cjsx')
SortOptions = require('./components/sortoptions.cjsx')

sortConfig = [
	{Price: 'Price'}
	{SKU: 'SKU'}
	{Quantity: 'Quantity'}
	{minPrice: 'Min. Price'}
	{maxPrice: 'Max. Price'}
]

#GroupList = require('./components/grouplist.cjsx')
#ProductGroups = React.createClass(GroupList)
model =	require('db-model').get('default')

BaseList = require('./components/baselist.cjsx')
RepricerList = {}
_.assign(RepricerList, BaseList)
_.assign(RepricerList, {
	getItemElement: (item)->
		return <RepricerItem key={item.SKU} data={item} view={@handleView}/>
	getSortElement: ()->
		<SortOptions config={sortConfig} onChange={@state.onSortChange} />
})
RepricerList = React.createClass(RepricerList)

# Page 'Repricer' module
Repricer = React.createClass
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
					<RepricerFilter onFilterChange={@onFilterChange} />
				</div>
			</div>
			<div className="row">
				<RepricerList data={@state.data} onSortChange={@onSortChange} />
			</div>
		</div>

module.exports = Repricer
