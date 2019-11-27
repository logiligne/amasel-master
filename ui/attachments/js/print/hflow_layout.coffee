define 'print/hflow_layout', ['print/dimUnit','print/dimBox'], (DimUnit, DimBox)->
	class HFlowLayout
		constructor: (pdf,pageOptions)->
			@page = if pageOptions instanceof DimBox then pageOptions else new DimBox(pageOptions)
			@page = @page.toPt()
			@x = @page.minX.toPt()
			@y = @page.minY.toPt()
			@hY = @y.copy()
			@pdf = pdf
			@setFontSize("4mm")
			@numPages = 1
		setFontSize: (size)->
			@fontSize = new DimUnit(size).toPt()
			@pdf.fontSize(@fontSize.v)
		startBox: (box) ->
			@_nextRow box
		endBox: (box) ->
			@_appendBox box
		addTextBox: (string, box)->
			@startBox(box)
			@addText(string, box)
			@endBox(box)
		addText: (string, box)->
			box = box.toPt()
			x = @x.v + (box.marginLeft?.v ? 0)
			y = @y.v + (box.marginTop?.v  ? 0) #+ @fontSize.v
			w = box.width.v -  (box.marginRight?.v ? 0) - (box.marginLeft?.v ? 0)
			h = box.height.v - (box.marginBottom?.v ? 0) - (box.marginTop?.v  ? 0)
			#@pdf.text(string, @x.v + (box.marginLeft.toPt().v ? 0),@y.v + (box.marginTop.toPt().v ? 0) + @fontSize.toPt().v)
			lines = string.split('\n')
			opts = {
					lineBreak : false
					width: w
					height: @pdf.currentLineHeight()
					ellipsis: true
					indent: 0
					paragraphGap : 0
			}
			@pdf.text(lines[0], x ,y , opts)
			for i in [1...lines.length]
				h -= @pdf.currentLineHeight()
				if h <=0
					break
				@pdf.text(lines[i], opts)
			# @pdf.lineWidth(3).strokeOpacity(.5)
			# @pdf.rect(@x.v,@y.v, box.width.v, box.height.v).stroke("blue")
			# @pdf.lineWidth(1).strokeOpacity(1)
			# @pdf.rect(x,y, w, h).stroke("red")
		addImage: (box, imgData, imageWidth, imageHeight, position)->
			x = @x.v + (box.marginLeft.toPt().v ? 0)
			y = @y.v + (box.marginTop.toPt().v ? 0)
			inW = box.width.toPt().v - (box.marginRight.toPt().v ? 0) - (box.marginLeft.toPt().v ? 0)
			inH = box.height.toPt().v - (box.marginBottom.toPt().v ? 0) - (box.marginTop.toPt().v ? 0)
			iW = new DimUnit(imageWidth).toPt().v
			iH = new DimUnit(imageHeight).toPt().v
			# make image smaller if it doesn't fit in the inner box
			if iW > inW
				iW = inW
			if iH > inH
				iH = inH
			unless position in ['TopLeft','TopRight','BottomLeft','BottomRight']
				position = 'BottomRight'
			switch position
				when 'TopLeft'
					x += 0
					y += 0
				when 'TopRight'
					x += inW - iW
					y += 0
				when 'BottomLeft'
					x += 0
					y += inH - iH
				when 'BottomRight'
					x += inW - iW
					y += inH - iH
			@pdf.image(imgData,{ x: x, y:y, width:iW, height:iH})
		addSpace: (box)->
			@_appendBox box
		_nextRow: (box)->
			box = box.toPt()
			x = @x.copy().add( box.width ).v
			y = @y.copy().v
			move = false
			# next row?
			if x > @page.maxX.v
				x = @page.minX.v
				y = @hY.v
				move = true
			# next page?
			if (y+box.height.v) > @page.height.v
				x = @page.minX.v
				y = @page.minY.v
				@hY = @page.minY.copy()
				@pdf.addPage()
				@numPages++
				move = true
			if move
				@x.v = x
				@y.v = y
		_appendBox: (box)->
			@x.add( box.width )
			if (@y.v+box.height.v) > @hY.v
				@hY.v = (@y.v+box.height.v)
		@numObjectsPerPage: (pageOptions, box, hspace, vspace)->
			fakePdf =
				addPage: ()->
				fontSize: ()->
				text: ()->
				rect: ()-> fakePdf
				stroke: ()-> fakePdf
				fillOpacity: ()-> fakePdf
				strokeOpacity: ()-> fakePdf
				lineWidth: () ->fakePdf
				currentLineHeight: ()-> fakePdf
			spacingBox = new DimBox({
				Width: hspace,
				Height: vspace,
			})
			spacingBox.height.add(box.height)
			spacingBox = spacingBox.toPt()

			l = new HFlowLayout(fakePdf ,pageOptions)
			i = 0
			while(i<250)
				l.addTextBox('',box)
				l.addSpace(spacingBox)
				if l.numPages > 1
					break
				i++
			return i
	HFlowLayout
