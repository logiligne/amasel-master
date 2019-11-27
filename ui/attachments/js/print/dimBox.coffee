define 'print/dimBox', ['underscore.string', 'print/dimUnit'], (_s,DimUnit)->
	class DimBox
		keys : ["Height","Width","MarginTop","MarginBottom","MarginLeft","MarginRight",]
		constructor: (obj)->
			if(!obj)
				throw new Error('DimBox initializer must be an object.')

			for k,v of obj
				for key in @keys
					if _s.endsWith(k,key)
						if v instanceof DimUnit
							@[@keyAttr(key)] = v.copy()
						else
							@[@keyAttr(key)] = new DimUnit(v)
						break
			if(!@width || !@height)
				throw new Error('DimBox initializer must be an object with at least Width & Height.')
			@marginLeft ?= new DimUnit(0)
			@marginTop  ?= new DimUnit(0)
			@marginRight ?= new DimUnit(0)
			@marginBottom ?= new DimUnit(0)
			@minX = @marginLeft ? new DimUnit(0)
			@minY = @marginTop  ? new DimUnit(0)
			@maxX = if @marginRight then @width.copy().sub(@marginRight) else @width
			@maxY = if @marginBottom then @height.copy().sub(@marginBottom) else @height

		keyAttr: (key)->
			key[0].toLowerCase() + key.slice(1)

		toPt : ()->
			o  = {}
			for key in @keys
				v = @[@keyAttr(key)]
				if v
					o[key] = v.toPt()
			return new DimBox(o)
