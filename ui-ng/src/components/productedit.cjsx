_ = require('lodash')
React = require('react')
BaseModal = require('./basemodal.cjsx')
ReactBootstrap = require('react-bootstrap')
FieldMixin = require('../mixins/fieldmixin.cjsx')
FormMixin = require('../mixins/formmixin.cjsx')
ProductInfo = require('./productinfo.cjsx')

Button = ReactBootstrap.Button
Input = ReactBootstrap.Input
Row = ReactBootstrap.Row
Col = ReactBootstrap.Col
Label = ReactBootstrap.Label
OverlayTrigger = ReactBootstrap.OverlayTrigger
Tooltip = ReactBootstrap.Tooltip

BaseModalComponent = React.createClass(BaseModal)
ProductEditContent = React.createClass
	mixins: [FormMixin, FieldMixin]
	getInitialState: ()->
		state =
			data: {}
			quantityConf:
				onKeyUp: @onQuantityChange
				ref: 'Quantity'

			priceConf:
				onKeyUp: @onPriceChange
				ref: 'Price'

		_.assign state.data, @props.data
		return state

	onPriceChange: (event)->

	onQuantityChange: (event)->

	render: ()->
		console.log 'Price: ' + @state.data.Price

		<Input wrapperClassName='wrapper'>
			<Row>
				<Col xs={4}>
					{@getNumericField('Quantity', @state.data.Quantity, @state.quantityConf)}
					{@getNumericField('Price', @state.data.Price, @state.priceConf)}
				</Col>
				<Col xs={1}>&nbsp;</Col>
				<Col xs={7}>
					<ProductInfo data={@state.data} />
				</Col>
			</Row>
		</Input>

ProductEdit = React.createClass
	onUpdate: ()->
		console.log @refs.content.getValues()
	render: ()->
		buttons = [
			<Button onClick={@props.onRequestHide} ref='close'>Close</Button>
			<Button onClick={@onUpdate} type="submit">Update</Button>
		]
		<BaseModalComponent {...@props} buttons={buttons}>
			<ProductEditContent {...@props} ref='content' />
		</BaseModalComponent>

module.exports = ProductEdit
