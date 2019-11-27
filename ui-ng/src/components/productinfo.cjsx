React = require('react')

ProiductInfo = React.createClass
	render: ()->
		<div>
			<p style={"clear": 'both'}>
				<img style={"maxWidth":75, "float": 'right'} src={@props.data.imageSmall} />
				{@props.data.title}
			</p>
			<h4>ASIN</h4>
			<p>{@props.data.ASIN}</p>
			<h4>SKU</h4>
			<p>{@props.data.SKU}</p>
		</div>

module.exports = ProiductInfo
