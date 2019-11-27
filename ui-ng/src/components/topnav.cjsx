React = require('react')
TopNavSwitch = require('./topnavswitch.cjsx')
TopNavActions = require('./topnavactions.cjsx')

TopNav = React.createClass
	render: ()->
		compStyle = {
			marginBottom: 0
		}
		<nav className="navbar navbar-default " role="navigation" style={compStyle}>
			<TopNavActions />
			<TopNavSwitch />
		</nav>

module.exports = TopNav
