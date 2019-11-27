SKIP_PROPS=
	__super__: true
	constructor: true

Function::include = (mixin) ->
  if not mixin
    return throw 'Supplied mixin was not found'

  mixin = mixin.prototype if typeof mixin is 'function'

  for methodName, funct of mixin when not SKIP_PROPS[methodName]
    if not @prototype.hasOwnProperty(methodName)
      @prototype[methodName] = funct
  @
