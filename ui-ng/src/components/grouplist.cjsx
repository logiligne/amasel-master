React = require('react')
model =	require('db-model').get('default')

GroupList =
	getGroupsCounts: ()->
		r = {}
		console.log '=>', model.products._groups
		for group in model.products.getGroups()
			r[group] = model.products.getNumberOfKeysInGroup(group)
		r
	componentDidMount: ()->
		@setState({
			groups: @getGroupsCounts()
		})
		model.products.refEvents('GroupList').on 'groupsChanged', ()=>
			console.log 'model.products.changed',model.products.getGroups()
			@setState({
				groups: @getGroupsCounts()
			})
	componentWillUnmount: ()->
		model.products.unrefEvents('GroupList')
	getInitialState: ()->
		return {
			groups: [],
		}
	buildElements: (items)->
		for group,count of @state.groups
			<button type="button" className="btn btn-default">{group} <span className="badge">{count}</span></button>

	render: ()->
		<div className="btn-group" role="group">
			{@buildElements()}
		</div>

module.exports = GroupList
