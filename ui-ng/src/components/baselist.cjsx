React = require('react')
SortOptions = require('./sortoptions.cjsx')
BaseItem = require('./baseitem.cjsx')
BaseItemElement = React.createClass(BaseItem)
Pager = require('react-pager')

sortConfig = [
	{Price: 'Price'}
	{SKU: 'SKU'}
	{Quantity: 'Quantity'}
]

BaseList =
	_slice: (data, page = 0)->
		start	= page * @state.perPage
		end 	= start + @state.perPage
		data[start...end]
	### Component API ###
	getInitialState: ()->
		return {
			perPage: 20,
			currentPage: 0,
			data: [],
			isModalOpen: false,
			onSortChange: @props.onSortChange
		}
	# Paging
	onPageChange: (page)->
		@setState({ currentPage: page })
	# UI abstraction
	buildElements: (items)->
		if items?
			elements = items.map (item)=>
				@getItemElement item
		return elements
	getItemElement: (item)->
		return <BaseItemElement key={item.SKU} data={item} view={@handleView}/>
	getSortElement: ()->
		<SortOptions config={sortConfig} onChange={@state.onSortChange} />
	render: ()->
		numPages = @props.data.length / @state.perPage
		elements = @buildElements @_slice(@props.data, @state.currentPage)
		sortelem = @getSortElement()

		<div className="col-md-12">
			<div className="row vcenter">
				<div className="col-md-7">
					<Pager
						total={numPages}
						current={@state.currentPage}
						visiblePages={5}
						onPageChanged={@onPageChange}
					/>
				</div>
				<div className="col-md-3" style={paddingTop: '27px'}>showing {elements.length} of {@props.data.length} items</div>
				<div className="col-md-2" style={paddingTop: '20px'}>{sortelem}</div>
			</div>
			<div className="row">
				<div className="col-md-12 flex-container">
					{elements}
				</div>
			</div>
		</div>

module.exports = BaseList
