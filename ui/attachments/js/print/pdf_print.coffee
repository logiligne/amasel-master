define 'print/pdf_print', [
		  'pdfkit',    'blob-stream','print/dimUnit','print/dimBox','print/hflow_layout'
	], ( PDFDocument, blobStream,   DimUnit,        DimBox,        HFlowLayout)->
		PdfPrint= {}

		PdfPrint.preProcess = (pdf,order,maxLen)->
			o = angular.copy(order)
			try
				pd = new Date(o.PurchaseDate)
				o.PurchaseDate = pd.toLocaleString()
			catch e

			if o.ShippingAddress
				l = []
				l.push( o.ShippingAddress.AddressLine1) if o.ShippingAddress.AddressLine1
				l.push( o.ShippingAddress.AddressLine2) if o.ShippingAddress.AddressLine2
				l.push( o.ShippingAddress.AddressLine3) if o.ShippingAddress.AddressLine3
				o.ShippingAddress.AddressLines = l.join('\n')
			return o
		PdfPrint.getScope = (config)->
			scope = {};
			return scope

		PdfPrint.renderBegin = (pdf, interpolate, scope ,config)->
		PdfPrint.renderEnd = (pdf, interpolate, scope ,config)->

		PdfPrint.relativeFontSize = (amount)->
		  fs = layout.fontSize.copy()
		  fs.add(new DimUnit(ammout))
		  layout.setFontSize(fs)

		PdfPrint.renderLabels = (interpolate, empty, orders, config, resultCb)->
			scope = PdfPrint.getScope(config)
			width = new DimUnit(config.pageOptions.pageWidth).toPt().v
			height = new DimUnit(config.pageOptions.pageHeight).toPt().v
			orientation = 'portrait'
			if width > height
				orientation = 'landscape'
			#pdf = new jsPDF(orientation ,'mm',[width , height])
			pdf = new PDFDocument({size: [width , height] })
			stream = pdf.pipe(blobStream())
			layout = new HFlowLayout(pdf,config.pageOptions)
			layout.setFontSize(config.labelsOptions.fontSize)
			labelBox = new DimBox(config.labelsOptions)
			spacingBox = new DimBox({
				Width: config.labelsOptions.labelHorizontalSpacing,
				Height: config.labelsOptions.labelVerticalSpacing,
			})
			spacingBox.height.add(labelBox.height)

			for i in [0...empty]
				layout.addText('',labelBox)

			labelTemplate = config.labelsTemplate;
			labelTemplate  = labelTemplate.replace(/<br>/g,'');

			fontSize = new DimUnit(config.labelsOptions.fontSize)

			iFn = interpolate(labelTemplate);
			wm = config.labelWatermark

			for order in orders
				o = PdfPrint.preProcess(pdf, order, labelBox.width.toPt().v)
				# Add labels
				text = iFn(o)

				layout.startBox(labelBox)
				if wm.image?
					layout.addImage(labelBox, wm.image, wm.width, wm.height, wm.position )
				layout.addText(text,labelBox )

				onbox = new DimBox {
				  MarginLeft : labelBox.marginLeft,
				  MarginTop : labelBox.height.copy(),
				  Width : labelBox.width,
				  Height : new DimUnit("5mm")
				}
				currentFontSize = layout.fontSize
				layout.setFontSize("3mm")
				layout.addText(o.AmazonOrderId, onbox)
				layout.setFontSize(currentFontSize)
				layout.endBox(labelBox)

				layout.addSpace(spacingBox)
			# this is not working well in Firefox
			# pdfdata = pdf.output()
			# blob = new Blob(
			# 	[pdfdata],
			# 	{type: 'application/pdf'})
			# return window.URL.createObjectURL(blob)
			pdf.end()
			stream.on 'finish', ->
				url = stream.toBlobURL('application/pdf')
				resultCb(url)
			return

		PdfPrint
