_ = require('lodash')
React = require('react')
BaseModal = require('./basemodal.cjsx')
ReactBootstrap = require('react-bootstrap')
FieldMixin = require('../mixins/fieldmixin.cjsx')
FormMixin = require('../mixins/formmixin.cjsx')
ProductInfo = require('./productinfo.cjsx')
InputPercent = require('./inputpercent.cjsx')

Button = ReactBootstrap.Button
Input = ReactBootstrap.Input
Row = ReactBootstrap.Row
Col = ReactBootstrap.Col
Label = ReactBootstrap.Label
OverlayTrigger = ReactBootstrap.OverlayTrigger
Tooltip = ReactBootstrap.Tooltip

BaseModalComponent = React.createClass(BaseModal)
RepricerEditContent = React.createClass
	mixins: [FormMixin, FieldMixin]
	getInitialState: ()->
		state =
			data: {}
			minPriceConf:
				onKeyUp: @minPriceChange
				ref: 'minPrice'

			maxPriceConf:
				onKeyUp: @maxPriceChange
				ref: 'maxPrice'

		_.assign state.data, @props.data
		return state

	minPriceChange: (event)->

	maxPriceChange: (event)->

	render: ()->
		<Input wrapperClassName='wrapper'>
			<Row>
				<Col xs={4}>
					{@getNumericField('Minimal Price', @state.data.Quantity, @state.minPriceConf)}
					{@getNumericField('Maximum Price', @state.data.Price, @state.maxPriceConf)}
					<InputPercent label="Offset" />
				</Col>
				<Col xs={1}>&nbsp;</Col>
				<Col xs={7}>
					<ProductInfo data={@state.data} />
				</Col>
			</Row>
		</Input>

RepricerEdit = React.createClass
	onUpdate: ()->
		console.log @refs.content.getValues()
	render: ()->
		buttons = [
			<Button onClick={@props.onRequestHide} ref='close'>Close</Button>
			<Button onClick={@onUpdate} type="submit">Update</Button>
		]
		<BaseModalComponent {...@props} buttons={buttons}>
			<RepricerEditContent {...@props} ref='content' />
		</BaseModalComponent>

module.exports = RepricerEdit
