React = require('react')
ReactBootstrap = require('react-bootstrap')
Modal = ReactBootstrap.Modal
Button = ReactBootstrap.Button

BaseModal =
	render: ()->
		<Modal {...@props} bsStyle='primary' animation={false}>
			<div className='modal-body'>
				{@props.children}
				<div className='modal-footer'>
					{@props.buttons}
				</div>
			</div>
		</Modal>

module.exports = BaseModal
