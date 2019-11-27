React = require('react')
model =	require('db-model').get('default')

Printing = require('./components/settingsprinting.cjsx')
Vat = require('./components/settingsvat.cjsx')
Screen = require('./components/settingsscreen.cjsx')

Settings = React.createClass
	render: ()->
		config =
			'printing'	: Printing
			'screen'	: Screen
			'vat'		: Vat

		SettingsContent = config[@props.section]

		<div className="col-lg-12">
			<div className="row"><div className="col-lg-12">&nbsp;</div></div>
			<div className="row">
				<div className="col-lg-12">
					<SettingsContent />
				</div>
			</div>
		</div>

module.exports = Settings
