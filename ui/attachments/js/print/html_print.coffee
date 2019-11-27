define 'print/html_print', ['jquery','print/dimUnit'], ($,DimUnit)->
	HtmlPrint = {}
	HtmlPrint.preProcess = (order)->
		o = angular.copy(order)
		l = []
		l.push( o.ShippingAddress.AddressLine1 ) if o.ShippingAddress.AddressLine1
		l.push( o.ShippingAddress.AddressLine2 ) if o.ShippingAddress.AddressLine2
		l.push( o.ShippingAddress.AddressLine3 ) if o.ShippingAddress.AddressLine3
		o.ShippingAddress.AddressLines = l.join('<br>')
		try
			pd = new Date(o.PurchaseDate)
			o.PurchaseDate = pd.toLocaleString()
		catch e
		return o
	HtmlPrint.getScope = (config)->
		scope = {};
		angular.extend(scope, config.pageOptions )
		angular.extend(scope, config.labelsOptions )
		pageWidthWithoutMargins = ()->
			pw = new DimUnit(config.pageOptions.pageWidth)
			pml = new DimUnit(config.pageOptions.pageMarginLeft)
			pmr = new DimUnit(config.pageOptions.pageMarginRight)
			return pw.sub(pml).sub(pmr).toString()
		scope.pageWidthWithoutMargins = pageWidthWithoutMargins()
		return scope
		
	HtmlPrint.renderBegin = (interpolate, scope ,config)->
		iFn = interpolate(config.printPageBegin);
		return iFn(scope)

	HtmlPrint.renderEnd = (interpolate, scope ,config)->
		iFn = interpolate(config.printPageEnd);
		return iFn(scope)
		
	# HtmlPrint.renderLabels = (interpolate, empty, orders, config, bare)->
	# 	scope = HtmlPrint.getScope(config)
	# 	template = ''
	# 	if not bare?
	# 		template += HtmlPrint.renderBegin(interpolate, scope, config)
	# 	# Page break counter
	# 	counter = 0;
	# 	pageBreak = () ->
	# 		counter++;
	# 		if(counter >= scope.labelsPerPage)
	# 			counter = 0
	# 			return true
	# 		return false
	# 	
	# 	for i in [0...empty]
	# 		template += '<div class="label"></div>'
	# 		if pageBreak()
	# 			template += '<div class="page-break"></div>'
	# 	
	# 	counter = 0
	# 	
	# 	iFn = interpolate(config.labelsTemplate);
	# 	for order in orders
	# 		o = HtmlPrint.preProcess(order)
	# 		
	# 		template += '\n<div class="label">\n'
	# 		template += iFn(o)
	# 		template += '\n</div>\n'
	# 		if pageBreak()
	# 			template += '<div class="page-break"></div>'
	# 	
	# 	if not bare?
	# 		template += HtmlPrint.renderEnd(interpolate, scope, config)
	# 	blob = new Blob(
	# 		[pdfdata],
	# 		{type: 'text/html'})
	# 	return window.URL.createObjectURL(blob)
		
	HtmlPrint.prepareOrderTemplate = (config)->
		template = {}
		t = $('<div>' + config.orderTemplate+ '</div>')
		t.find('table.item-list').each (tableIndex, tableEl)->
			table = $(tableEl)
			console.log 'Process table'
			table.find('> * > tr').each (trIndex, trEl)->
				html = $(trEl).clone().wrap('<p>').parent().html();
				console.log 'Peocess row', html
				if html.match(/\{\{\s*item\./)
					console.log 'hasItem'
					id = 'itemList_' + tableIndex + '_' + trIndex
					template[id] = html
					$(trEl).replaceWith('{{ '+id+' }}')
		return {main: t.html(), lists: template}
		
	HtmlPrint.renderOrder = (interpolate, order, t, config)->
		itemLists = {}
		o = HtmlPrint.preProcess(order)
		for listName, listTemplate of t.lists
			iFn = interpolate(listTemplate)
			itemLists[listName] = ''
			for item in o.items
				o.item = item
				itemLists[listName] += iFn(o)
		angular.extend(o, itemLists )
		iFn = interpolate(t.main)
		out = iFn(o)
		out += '<div class="page-break"></div>'
		return out
	
	HtmlPrint.renderOrders = (interpolate, empty, orders, config, bare)->
		scope = HtmlPrint.getScope(config)
		template = ''
		if not bare?
			template += HtmlPrint.renderBegin(interpolate, scope, config)
		
		t = HtmlPrint.prepareOrderTemplate(config)
		console.log {'t':t}
		for order in orders
			template += HtmlPrint.renderOrder(interpolate, order, t, config)
		
		if not bare?
			template += HtmlPrint.renderEnd(interpolate, scope, config)
		template
	HtmlPrint

