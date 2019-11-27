class RepricerResult

	@_definitions =
		ALREADY_LOWEST						: 'Already lowest offer'
		ITEM_INACTIVE							: 'Not active'
		NEED_RAISE_NO_MAX_PRICE		: 'No maximum price, and need to raise'
		NEED_LOWER_NO_MIN_PRICE		: 'No minimum price and need to lower'
		NEW_PRICE_BELOW_0_01			: 'New price below 0.01'
		NOT_IN_RANGE							: 'Outside min/max range'
		MY_PRICE_MISSING					: 'No my price'

	makeEnumVal = (id, description)->
		class EnumVal
			constructor: (@id, description)->
				@_description = description
			toString: ()->
				return @id
			description: ()->
				return @_description
		Object.freeze( new EnumVal(id, description) )
	for id, description of @_definitions
		#@[id] = makeEnumVal(id,description)
		@[id] = id

	constructor: (id)->
		unless RepricerResult._definitions[id]
			throw Error('Invalid RepricerResult id:' + id)
		@_val = makeEnumVal(id, RepricerResult._definitions[id])
		Object.freeze(@)

	toString: ()->
		@_val.toString()

	description: ()->
		@_val.description()

module.exports = RepricerResult

# if require.main is module
# 	a = new  RepricerResult('ALREADY_LOWEST')
# 	console.log(''+a, '->', a.description())
# 	b= RepricerResult.ITEM_INACTIVE
# 	console.log(''+b, '->', b.description())
