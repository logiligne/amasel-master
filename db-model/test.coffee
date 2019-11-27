_ = require('lodash')
require('./src/mixin')

class A
	constructor:()->
		console.log 'Construct A'
	fun:()->
		console.log 'fun()'

class Mixin
	funA:()->
		console.log 'funA()'

class B extends A
	@include(Mixin)

	constructor: ()->
		super()
		console.log 'Construct B'

b= new B()
b.fun()
b.funA()

console.log B.prototype
