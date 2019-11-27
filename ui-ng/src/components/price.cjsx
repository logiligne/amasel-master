React = require('react')

Price = React.createClass
	render: ()->
		iconsConf 	= {}
		iconsConf['up'] 		= 'fa fa-long-arrow-up'
		iconsConf['down'] 		= 'fa fa-long-arrow-down'
		iconsConf['nochange'] 	= 'fa fa-arrows-h'

		colorsConf = {}
		colorsConf['up']		= {color: 'green'}
		colorsConf['down']		= {color: 'red'}
		colorsConf['nochange']	= {color: 'grey'}

		indicator = ''

		if 	@props.indicator
			indicator = <i style={colorsConf[	@props.indicator]}
				className={iconsConf[@props.indicator]}></i>

		<span>
			{indicator} {@props.price}
		</span>

module.exports = Price
