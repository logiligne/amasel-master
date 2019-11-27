_ = require('lodash')
BasicCollection = require('./basic-collection')

class Selection extends BasicCollection
	constructor: (cfg)->
		super(cfg)
	getSelected: ()->
		k for k,v of @map when v is true

module.exports = Selection
