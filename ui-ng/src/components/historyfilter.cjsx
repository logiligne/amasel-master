React = require('react')
BaseFilter = require('./basefilter.cjsx')
WrapFilter = React.createClass(BaseFilter)

FormMixin = require('../mixins/formmixin.cjsx')
ReactBootstrap = require('react-bootstrap')
Input = ReactBootstrap.Input
Col = ReactBootstrap.Col
Row = ReactBootstrap.Row

HistoryFilter = React.createClass
	mixins: [FormMixin]
	getInitialState: ()->
		return {
			config: [
				{name:'SKU', field: 'SKU', role: 'startsWith', source: 'query', relation: ''}
				'or'
				{name:'ASIN', field: 'ASIN', role: 'has', source: 'query', relation: ''}
				'or'
				{name:'title', field: 'title', role: 'has', source: 'query', relation: ''}
			]
		}
	render: ()->
		<WrapFilter {...@props} config={@state.config} getValuesMethod={@getValues}>
			<Row>
				<Col xs={4}>
					<Input className="input-sm" type='text' label='' placeholder='Enter text' name="query" ref="query" />
				</Col>
				<Col xs={1}>
					<Input type='checkbox' checked label='SKU' name="SKU" ref="SKU" />
				</Col>
				<Col xs={1}>
					<Input type='checkbox' label='ASIN' name="ASIN" ref="ASIN" />
				</Col>
			</Row>
		</WrapFilter>

module.exports = HistoryFilter
