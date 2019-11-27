_ = require('lodash')
React = require('react')
ModalTrigger = require('react-bootstrap').ModalTrigger
ProductEdit = require('./productedit.cjsx')
model =	require('db-model').get('default')

BaseItem =
	getModalTitle: ()->
		"SKU: #{@props.data.SKU} / ASIN: #{@props.data.ASIN}"
	onSelectionChanged: (event)->
		model.productSelection.set(@props.data.SKU, event.target.checked)
		console.log model.productSelection.getSelected()
	render: ()->
		<div className="flex-item panel panel-default">
			<div className="panel-body">
				<div className="pull-left" style={height:75}>
					<a href="javascript: void(0)">
						<img style={"maxWidth":75} src={@props.data.imageSmall} />
					</a>
				</div>
				<div className="pull-right text-right">
					<div className="huge">SKU: <a href="javascript:void(0);">{@props.data.SKU}</a></div>
					<div className="huge">Price: {@props.data.Price}</div>
					<div className="huge">Qty: {@props.data.Quantity}</div>
				</div>
			</div>
			<div className="panel-footer" style={"padding": '5px'}>
				<span className="pull-left">
					<input type="checkbox" name="items[]" ref="items" onChange={@onSelectionChanged}/>
				</span>
				<span className="pull-right">
					<ModalTrigger modal={<ProductEdit title={@getModalTitle()} data={@props.data} />}>
						<a href="javascript: void(0)">Modify</a>
					</ModalTrigger>
				</span>
				<div className="clearfix"></div>
			</div>
		</div>

module.exports = BaseItem
