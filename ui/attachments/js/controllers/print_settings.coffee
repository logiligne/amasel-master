'use strict';
SAMPLE_ORDER =
	AmazonOrderId : 'xxxx-xxxxxxx-xxxxxxx'
	PurchaseDate  : "2013-02-20T10:16:58Z"
	SalesChannel : 'Amazon.de'
	OrderTotal:
		Amount: "XX.XX",
		CurrencyCode: "EUR"
	ShippingAddress:
		Name: "Christina Gruenewald"
		Phone: "02605 46 85 99"
		AddressLine1: "Storkower Strasse 51"
		AddressLine2: ""
		AddressLine3: ""
		PostalCode: "56283"
		City: "Morshausen"
		StateOrRegion: "Rhein-Hunsrück-Kreis"
		CountryCode: "DE"
		Country: "GERMANY"
	items:[{
			"QuantityOrdered": "1",
			"QuantityShipped": "1",
			"SellerSKU": "x-x-x-x",
			"Title": "Sample product with very very very long title, description and so on/More text, that should be clipped at some point",
			"ASIN": "XXXXXX",
			"ItemTax": { "Amount": "0.00", "CurrencyCode": "EUR"},
			"GiftWrapPrice": { "Amount": "0.00", "CurrencyCode": "EUR"},
			"ItemPrice": { "Amount": "3.49", "CurrencyCode": "EUR"},
			"PromotionDiscount": { "Amount": "0.00", "CurrencyCode": "EUR"},
			"GiftWrapTax": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ShippingTax": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ShippingPrice": { "Amount": "0.47", "CurrencyCode": "EUR" },
			"ShippingDiscount": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ConditionId": "New",
			"ConditionSubtypeId": "New",
		},{
			"QuantityOrdered": "2",
			"QuantityShipped": "2",
			"SellerSKU": "x-x-x-x",
			"Title": "WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW",
			"ASIN": "WWWWWWWWWW",
			"ItemTax": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"GiftWrapPrice": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ItemPrice": { "Amount": "1987.45", "CurrencyCode": "EUR" },
			"PromotionDiscount": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"GiftWrapTax": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ShippingTax": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ShippingPrice": { "Amount": "1.47", "CurrencyCode": "EUR"},
			"ShippingDiscount": { "Amount": "0.00", "CurrencyCode": "EUR" },
			"ConditionId": "New",
			"ConditionSubtypeId": "New",
		}
	]


define 'controllers/print_settings',
	['amaselApp', 'print/page_metrics', 'print/pdfmake_print', 'pdfmake', 'print/dimUnit', 'underscore'],
	(amaselApp,    PageMetrics,          pdfPrinter,     pdfMake,   DimUnit,        _) ->
		printSettingsCtrl = ($scope, $interpolate, $routeParams) ->
			$scope.currentPage = $routeParams.page || 'profiles'
			$scope.nav.title = "Print Settings"
			$scope.labelsTemplate = amaselApp.config.labelsTemplate
			$scope.labelWatermark = amaselApp.config.labelWatermark
			$scope.orderTemplate = amaselApp.config.orderTemplate
			$scope.screenPageSize = amaselApp.config.screenPageSize
			$scope.printTemplate = amaselApp.config.printSettings[amaselApp.config.currentPrintProfile].printTemplate
			$scope.printTemplateInput = JSON.stringify(_.omit($scope.printTemplate,'images'), null, 4)

			for i in [1..20]
				SAMPLE_ORDER.items.push(_.clone(SAMPLE_ORDER.items[0]))
			for o,idx in SAMPLE_ORDER.items
				o.QuantityOrdered = '' +idx
				o.SellerSKU = 'sku-item-' + idx
			currentProfile = ()->
				return amaselApp.config.printSettings[amaselApp.config.currentPrintProfile]

			$scope.show = (p)->
				$scope.currentPage = p

			$scope.refreshProfiles = ()->
				$scope.printProfiles = {}

				for name, profile of amaselApp.config.printSettings
					$scope.printProfiles[name] = profile
			$scope.refreshProfiles()

			$scope.currentPrintProfile = amaselApp.config.currentPrintProfile
			$scope.pageOptions = angular.copy(currentProfile().pageOptions)
			$scope.labelsOptions = angular.copy(currentProfile().labelsOptions)

			$scope.$on '$viewContentLoaded', () ->
				if PageMetrics.canCreate('#print-page-options')
					pm = new PageMetrics '#print-page-options', $scope.pageOptions
					pm.definePrintPage()
					pm.buildSettings()
					pm.draw()
				if PageMetrics.canCreate('#print-labels-options')
					pm = new PageMetrics '#print-labels-options', $scope.labelsOptions
					pm.defineLabels()
					pm.buildSettings()
					pm.draw()
			$scope.savePageOptions = ()=>
				amaselApp.config.save('printSettings.' + $scope.currentPrintProfile + '.pageOptions', $scope.pageOptions)
			$scope.newProfileName = ''
			$scope.newProfileComment = ''
			$scope.createProfile = ()=>
				if ($scope.newProfileName.lenght == 0 || $scope.newProfileName == 'default')
					return
				newProf = angular.copy(amaselApp.config.printSettings[$scope.currentPrintProfile])
				newProf.comment = $scope.newProfileComment
				amaselApp.config.save 'printSettings.'+$scope.newProfileName , newProf , ()->
					$scope.safeApply ()->
						$scope.refreshProfiles()
			$scope.deleteProfile = (profileName)=>
				amaselApp.config.save 'printSettings.'+profileName , null , ()->
					$scope.safeApply ()->
						$scope.refreshProfiles()
			$scope.setCurrentProfile = (profileName)=>
				amaselApp.config.save('currentPrintProfile', profileName)
			$scope.loadImage = ()=>
				if !$scope.printTemplate
					$scope.printTemplate = {}
				if !$scope.printTemplate.images
					$scope.printTemplate.images = {}
				input   = document.getElementById('newImageFile')
				imgName = document.getElementById('newImageName')
				if  !input.files[0]
					alert("Select an image file first")
					return
				if  imgName.value.length == 0
					alert("Image name cannot be empty")
					return
				file = input.files[0]
				fr = new FileReader()
				fr.onload = ()=>
					img = new Image()
					img.onload = () =>
						canvas = document.createElement('canvas')
						canvas.width = img.width
						canvas.height = img.height
						ctx = canvas.getContext("2d")
						ctx.fillStyle = 'rgba(255, 255, 255, 1.0)'
						ctx.fillRect(0, 0, canvas.width, canvas.height)
						ctx.drawImage(img,0,0)
						$scope.printTemplate.images[imgName.value] = canvas.toDataURL('image/jpeg');
					img.src = fr.result
				fr.readAsDataURL(file)
			$scope.deleteImage = (imgName)=>
				delete $scope.printTemplate.images[imgName]
			$scope.saveImages = ()=>
				amaselApp.config.save('printSettings.' + $scope.currentPrintProfile + '.printTemplate', $scope.printTemplate, 'replace')

			$scope.removeWatermark = ()=>
				delete $scope.labelWatermark.image
				canvas = document.getElementById("watermarkCanvas")
				# clear canvas
				canvas.width = canvas.width;
			$scope.templatePreview = ()=>
				try
					p = JSON.parse($scope.printTemplateInput);
				catch e
					alert('Invalid template definition:' +e )
					return
				if $scope.printTemplate
					p.images = $scope.printTemplate.images
				profile = $scope.currentPrintProfile;
				cfg = angular.copy(amaselApp.config);
				cfg.pageOptions = amaselApp.config.printSettings[profile].pageOptions;
				cfg.labelsOptions = amaselApp.config.printSettings[profile].labelsOptions;
				cfg.currentPrintProfile = profile
				cfg.printSettings[profile].printTemplate = p
				(new pdfPrinter(cfg)).renderLabels([SAMPLE_ORDER], (blobURL)->
					window.open(blobURL);
				)
			$scope.saveTemplate = ()=>
				try
					p = JSON.parse($scope.printTemplateInput);
				catch e
					alert('Invalid template definition:' +e )
					return
				if $scope.printTemplate
					p.images = $scope.printTemplate.images
				amaselApp.config.save('printSettings.' + $scope.currentPrintProfile + '.printTemplate', p, 'replace',() -> $scope.printTemplate = p)

		amaselApp.amaselMain.controller( 'PrintSettingsCtrl', printSettingsCtrl);

		return printSettingsCtrl;
