React = require('react')
ReactBootstrap = require('react-bootstrap')
TabbedArea = ReactBootstrap.TabbedArea
TabPane = ReactBootstrap.TabPane

SettingsPrinting = React.createClass
	getInitialState: ()->
		return {key: 1}

	handleSelect: (key)->
		@setState({key})

	render: ()->
		<TabbedArea activeKey={this.state.key} onSelect={this.handleSelect}>
			<TabPane eventKey={1} tab='Print profiles'>TabPane 1 content</TabPane>
			<TabPane eventKey={2} tab='Page setup'>TabPane 2 content</TabPane>
			<TabPane eventKey={3} tab='Page template'>TabPane 3 content</TabPane>
			<TabPane eventKey={4} tab='Images'>TabPane 4 content</TabPane>
		</TabbedArea>

module.exports = SettingsPrinting