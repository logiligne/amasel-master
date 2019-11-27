React = require('react')
ReactBootstrap = require('react-bootstrap')
Input = ReactBootstrap.Input
Glyphicon = ReactBootstrap.Glyphicon

InputPercent = React.createClass
	getInitialState: ()->
		return {
			isNormal: true
		}
	switchMode: ()->
		@setState
			isNormal: not @state.isNormal
	render: ()->
		symbol 	= if @state.isNormal then '%' else '$'
		after	= <a href="javascript: void(0)" onClick={@switchMode} >{symbol}</a>
		<Input bsSize="xsmall" type="text" addonAfter={after} {...@props} />

module.exports = InputPercent