define 'print/pdfmake_print', [
		  'pdfmake',	'handlebars',			'print/dimUnit',	'print/dimBox',	'print/hflow_layout',	'underscore'
	], ( pdfMake,		HandlebarsModule,	DimUnit,					DimBox,					HFlowLayout,					_)->
		Handlebars = HandlebarsModule.default
		TRANSLATIONS={
			UK:
				"Quantity": "Quantity"
				"Product details": "Product details"
				"Price": "Price"
				"Total[Column]": "Total"
				"Subtotal": "Subtotal"
				"Shipping": "Shipping"
				"Total":"Total"
				"Order total": "Order total"
				"VAT" : "VAT"
				"Net amount" : "Net amount"
			DE:
				"Quantity": "Menge"
				"Product details": "Produktdetails"
				"Price": "Preis"
				"Total[Column]": "Gesamt"
				"Subtotal": "Zwischensumme"
				"Shipping": "Versand"
				"Total":"Summe"
				"Order total": "Summe der bestellung"
				"VAT" : "VAT"
				"Net amount" : "Nettobetrag"
		}
		class PdfMakePrint
			constructor: (@config)->
				@lang = @config.lang ? 'DE'
				if TRANSLATIONS[@lang]
					@tr =  TRANSLATIONS[@lang]
				else
					@tr =  TRANSLATIONS['UK']
			preProcess: (pdf,order,maxLen)->
				o = angular.copy(order)
				try
					pd = new Date(o.PurchaseDate)
					o.PurchaseDate = pd.toLocaleDateString()
				catch e

				if o.ShippingAddress
					l = []
					l.push( o.ShippingAddress.AddressLine1) if o.ShippingAddress.AddressLine1
					l.push( o.ShippingAddress.AddressLine2) if o.ShippingAddress.AddressLine2
					l.push( o.ShippingAddress.AddressLine3) if o.ShippingAddress.AddressLine3
					o.ShippingAddress.AddressLines = l.join('\n')
				return o

			price: (itemPrice)->
				if !itemPrice
					return ' '
				cc = switch itemPrice.CurrencyCode
					when 'EUR' then '€'
					when 'USD' then '$'
					when 'GBP' then '£'
					else itemPrice.CurrencyCode
				cc + ' ' + itemPrice.Amount

			sumPrices: (prices...)->
				sum = 0
				for p in prices
					sum += parseFloat(if p then p.Amount else 0)
				{CurrencyCode: prices[0].CurrencyCode , Amount: ""+sum.toFixed(2)}
			detailedPrice: (item)->
				el =
					align: 'right'
					layout:{
						hLineWidth: (i)-> 0
						vLineWidth: (i)-> 0
						paddingLeft: (i)-> 0
						paddingRight: (i,node)-> if (i == node.table.widths.length-1 ) then 8 else 0
					}
					fontSize : 8
					table :
						widths: [70, 50]
						headerRows : 0
						body: [
							["#{@tr['Subtotal']}:", {text: @price(item.ItemPrice),alignment:'right' }]
							["#{@tr['Shipping']}:", {text: @price(item.ShippingPrice),alignment:'right' }]
							[{text:"#{@tr['Total']}:", bold:true},{text:@price( @sumPrices(item.ItemPrice, item.ShippingPrice)),alignment:'right', bold: true }]
						]
				return el
			orderItemsTable: (order)->
				tableEl =
					fontSize : 10
					margin: 14
					layout:{
						hLineWidth: (i, node)->
							if (i == 0 || i >= node.table.body.length-2)
								return 0
							if(i == node.table.headerRows) then 2 else 1
						vLineWidth: (i, node)-> if (i == 0 || i == node.table.widths.length) then  0  else 1
						hLineColor: (i)-> if i == 1 then 'black' else '#aaa';
						vLineColor: (i)-> return '#aaa'
						paddingLeft: (i)-> 5
						paddingRight: (i)-> 3
					}
					table:
						headerRows : 1
						widths: [30, '*', 60, 120]
						body: [[
							{
								text: "#{@tr['Quantity']}",
								style: "tableHeader"
								alignment: "right"
							},
							{
								"text": "#{@tr['Product details']}",
								"style": "tableHeader"
								alignment: "center"
							},
							{
								"text": "#{@tr['Price']}",
								"style": "tableHeader"
								alignment: "center"
							},
							{
								"text": "#{@tr['Total[Column]']}",
								"style": "tableHeader"
								alignment: "center"
							} ]]
				itemList = order.items ? []
				for item in itemList
					[col1, col2, col3, col4] = [{}, {}, {}, {}]
					tableEl.table.body.push([col1, col2, col3 ,col4])
					col1.alignment= 'right'
					col1.text = item.QuantityOrdered
					title = item.Title
					if title.length > 100
						title = title.substring(0,100)
						title += '…'
					col2.stack = [
						  { text: title },
							{
								columns:
									[
										{
											width: '*',
											text: [ "SKU: " ,  { text: item.SellerSKU, bold: true } ]
										},
										{
											width: 80,
											text: [ "ASIN: " , item.ASIN],
											fontSize : 8
										}]
							}
					]
					col3.alignment= 'right'
					if item.QuantityOrdered > 0
						col3.text = @price(item.ItemPrice)
						_.extend(col4, @detailedPrice(item))
					else
						col3.text = ""
						col4.text = ""
					col4.alignment= 'right'
				sumCol =
					colSpan: 4
					alignment: 'right'
					text: [ "#{@tr['Order total']}: " ,{ text: @price(order.OrderTotal),bold:true} ]
				tableEl.table.body.push([sumCol,'','',''])
				vatAmount = _.clone(order.OrderTotal)
				vatAmount.Amount = (parseFloat(order.OrderTotal.Amount) * (@config.vat/100)).toFixed(2)
				vatCol =
					colSpan: 4
					alignment: 'right'
					text: [ "#{@tr['VAT']} " + @config.vat + '%: ' ,{ text: @price(vatAmount),bold:true} ]
				tableEl.table.body.push([vatCol,'','',''])
				neto = _.clone(vatAmount)
				neto.Amount = (parseFloat(order.OrderTotal.Amount) - parseFloat(vatAmount.Amount)).toFixed(2)
				totalCol =
					colSpan: 4
					alignment: 'right'
					text: [ "#{@tr['Net amount']} : " ,{ text: @price(neto),bold:true} ]
				tableEl.table.body.push([totalCol,'','',''])
				return tableEl
			renderTemplate: (template, order)->
				replace = (val, key)=>
					if typeof val == 'string' && val.indexOf('{{') >=0
						if val =='{{itemsTable}}'
							val = @orderItemsTable(order)
						else
							templateFn = Handlebars.compile(val, {noEscape:true});
							val = templateFn(order);
					else if Array.isArray(val)
						val = _.map(val, replace)
					else if typeof val == 'object'
						val = _.mapObject(val, replace)
					return val
				return replace(template)

			renderLabels: (orders, resultCb)->
				printTemplate = @config.printSettings[@config.currentPrintProfile].printTemplate

				#console.log 'preview', p
				w = new DimUnit(@config.pageOptions.pageWidth).toPt().v
				h = new DimUnit(@config.pageOptions.pageHeight).toPt().v
				generatedTemplate = {}
				if w>h
					generatedTemplate.pageOrientation = "landscape"
					generatedTemplate.pageSize =
						width: h
						height: w
				else
					generatedTemplate.pageOrientation = "portrait"
					generatedTemplate.pageSize =
						width: w
						height: h
				generatedTemplate.pageMargins =
					left:  new DimUnit(@config.pageOptions.pageMarginLeft).toPt().v
					right:  new DimUnit(@config.pageOptions.pageMarginRight).toPt().v
					top: new DimUnit(@config.pageOptions.pageMarginTop).toPt().v
					bottom:  new DimUnit(@config.pageOptions.pageMarginBottom).toPt().v
				generatedTemplate.images = printTemplate.images
				generatedTemplate.background = printTemplate.background
				generatedTemplate.content = []
				for order, index in orders
					o = @preProcess(null, order, 0)
					o.fortune_cookie = @config.fortune_cookie
					# Add labels
					c = printTemplate.content
					if index < orders.length-1
						c = c.concat([{text:'', pageBreak:"after"}])
					o.orderNumber = "#{index+1}/#{orders.length}"
					c = @renderTemplate( c, o )
					generatedTemplate.content = generatedTemplate.content.concat(c)

				try
					#console.log(JSON.stringify(generatedTemplate))
					pdfMake.createPdf(generatedTemplate).getBuffer((buffer)->
						blob = new Blob([buffer], {type: 'application/pdf'})
						url = URL.createObjectURL(blob)
						resultCb(url)
					{})
				catch e
					alert('Error:' + e)
		PdfMakePrint
