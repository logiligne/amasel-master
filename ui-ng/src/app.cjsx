# Must have core libs
React = require('react')
Crossroads = require('crossroads')
Hasher = require('hasher')

# Initialization
parseHash = (newHash, oldHash)->
	Crossroads.parse(newHash)

Hasher.initialized.add(parseHash)
Hasher.changed.add(parseHash)
Hasher.prependHash = '!';
Hasher.setHashSilent = (hash)->
	@changed.active = false
	@setHash hash
	@changed.active = true

# Global objects
EventEmitter = require('events').EventEmitter
Emitter = new EventEmitter

window.Emitter = Emitter
window.Hasher = Hasher || {}

class App
	start: ()->
		console.log "The main application has started"
		content = document.getElementById "react-router-path"
		topNavArea = document.getElementById "react-topnav"
		TopNav = require('./components/topnav.cjsx')

		Crossroads.addRoute '/', ()->
			Products = require('./products.cjsx')

			React.render <TopNav />, topNavArea
			React.render <Products />, content

		Crossroads.addRoute '/repricer', ()->
			Repricer = require('./repricer.cjsx')

			React.render <TopNav />, topNavArea
			React.render <Repricer />, content

		Crossroads.addRoute '/repricer/history', ()->
			RepHistory = require('./history.cjsx')

			React.render <TopNav />, topNavArea
			React.render <RepHistory />, content

		Crossroads.addRoute '/settings/{page}', (page)->
			Settings = require('./settings.cjsx')
			React.render <TopNav />, topNavArea
			React.render <Settings section={page} />, content

		# always call it at the end!!!
		Hasher.init()

module.exports = App