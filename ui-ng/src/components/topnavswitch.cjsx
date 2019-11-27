React = require('react')

TopNavSwitch = React.createClass
	render: ()->
		<ul className="nav navbar-top-links navbar-left">
			<li>
				<a href="javascript: void(0);" id="menu-switch">
					<i className="glyphicon glyphicon-menu-hamburger">Menu</i>
				</a>
			</li>
		</ul>

module.exports = TopNavSwitch
