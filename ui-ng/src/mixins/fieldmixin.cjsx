_ = require('lodash')
React = require('react')
ReactBootstrap = require('react-bootstrap')
Input = ReactBootstrap.Input

FieldMixin =
	getNumericField: (label, val, props={})->
		fieldName = props.ref if props.ref
		<Input bsSize="xsmall" name={fieldName}
			defaultValue={val} type='text' label={label}  {...props} />

	_getErrorObj: (msg)->
		error	=
			bsStyle: 'error'
			hasFeedback: true
			message: msg

	_getWarningObj: (msg)->
		warning =
			bsStyle: 'warning'
			hasFeedback: true
			message: msg

module.exports = FieldMixin