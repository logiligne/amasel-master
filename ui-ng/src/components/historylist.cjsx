_ = require('lodash')
React = require('react')
BaseList = require('./baselist.cjsx')
SortOptions = require('./sortoptions.cjsx')
Price = require('./price.cjsx')

sortConfig = [
	{SKU: 'SKU'}
	{Price: 'New Price'}
	{deltaPrice: 'Delta Price'}
	{date: 'Date'}
]

HistoryList = {}
_.assign(HistoryList, BaseList)
_.assign(HistoryList, {
	getSortElement: ()->
		<SortOptions config={sortConfig} onChange={@state.onSortChange} />

	buildElements: (items)->
		if items?
			elements = items.map (item)=>
				indicators = ['up', 'down', 'nochange']
				testIndicator = indicators[_.random(0, indicators.length-1)]
				<tr>
					<td>{item.SKU}</td>
					<td><Price price={item.Price} indicator={testIndicator} /></td>
					<td>Table cell</td>
					<td>Table cell</td>
				</tr>

		<table className="table table-striped" style={backgroundColor: '#ffffff'}>
			<thead>
				<tr>
					<th># SKU</th>
					<th>New price</th>
					<th>Delta price</th>
					<th>Date</th>
				</tr>
			</thead>
			<tbody>
			{elements}
			</tbody>
		</table>
})

HistoryList = React.createClass(HistoryList)
module.exports = HistoryList