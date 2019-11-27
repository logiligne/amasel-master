React = require('react')

TopNavActions = React.createClass
	render: ()->
		<ul className="nav navbar-top-links navbar-right">
			<li className="dropdown">
				<a className="dropdown-toggle" data-toggle="dropdown" href="#" aria-expanded="true">
					<i className="fa fa-bell fa-fw"></i>  <i className="fa fa-caret-down"></i>
				</a>
				<ul className="dropdown-menu dropdown-alerts">
					<li>
						<a href="#" className="active">
							<div>
								<i className="fa fa-comment fa-fw"></i> New Comment
								<span className="pull-right text-muted small">4 minutes ago</span>
							</div>
						</a>
					</li>
					<li className="divider"></li>
					<li>
						<a href="#" className="active">
							<div>
								<i className="fa fa-twitter fa-fw"></i> 3 New Followers
								<span className="pull-right text-muted small">12 minutes ago</span>
							</div>
						</a>
					</li>
				</ul>
			</li>
			<li className="dropdown">
				<a className="dropdown-toggle" data-toggle="dropdown" href="#">
					<i className="fa fa-user fa-fw"></i>  <i className="fa fa-caret-down"></i>
				</a>
				<ul className="dropdown-menu dropdown-user">
					<li><a href="#"><i className="fa fa-user fa-fw"></i>User Profile</a>
					</li>
					<li className="divider"></li>
					<li><a href="login.html"><i className="fa fa-sign-out fa-fw"></i> Logout</a>
					</li>
				</ul>
			</li>
		</ul>

module.exports = TopNavActions
