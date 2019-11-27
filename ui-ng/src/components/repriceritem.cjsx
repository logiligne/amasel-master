_ = require('lodash')
React = require('react')
ModalTrigger = require('react-bootstrap').ModalTrigger
model =	require('db-model').get('default')
RepricerEdit = require('./repriceredit.cjsx')

RepricerItem = React.createClass
	getModalTitle: ()->
		"SKU: #{@props.data.SKU} / ASIN: #{@props.data.ASIN}"
	onSelectionChanged: (event)->
		model.productSelection.set(@props.data.SKU, event.target.checked)
		console.log model.productSelection.getSelected()
	render: ()->
		<div className="flex-item panel panel-default">
			<div className="panel-body row">
				<div className="col-xs-2" style={height:75}>
					<a href="javascript: void(0)">
						<img style={"maxWidth":75} src={@props.data.imageSmall} />
					</a>
				</div>
				<div className="col-xs-10">
					<div class="row">
						<div className="col-xs-8 text-right" style={"paddingRight": '0px', "paddingRight": '0px'}>
							<div>SKU: &nbsp;</div>
							<div>Current price: &nbsp;</div>
							<div>Qty: &nbsp;</div>
							<div>Min. price: &nbsp;</div>
							<div>Max. price: &nbsp;</div>
							<div>Offset: &nbsp;</div>
						</div>
						<div className="col-xs-4 text-left" style={"paddingLeft": '0px', "paddingRight": '0px'}>
							<div><a href="javascript:void(0);">{@props.data.SKU}</a></div>
							<div>{@props.data.Price}</div>
							<div>{@props.data.Quantity}</div>
							<div></div>
							<div></div>
							<div></div>
						</div>
					</div>
				</div>
			</div>
			<div className="panel-footer" style={"padding": '5px'}>
				<span className="pull-right">
					<ModalTrigger modal={<RepricerEdit title={@getModalTitle()} data={@props.data} />}>
						<a href="javascript: void(0)">Modify</a>
					</ModalTrigger>
				</span>
				<span className="pull-left">
					<input type="checkbox" name="items[]" ref="items" onChange={@onSelectionChanged}/>
				</span>
				<div className="clearfix"></div>
			</div>
		</div>

module.exports = RepricerItem
