"use strict";

define(
	'main'
	, [
		'jquery',
		'amaselApp',
		'controllers/main',
		'controllers/orders',
		'controllers/products',
		'controllers/purchase_orders',
		'controllers/print_settings',
		'controllers/screen_settings',
		'controllers/fortune_cookie_settings',
		'controllers/vat_settings',
		'controllers/reports',
		'controllers/repricer_status',
		'controllers/repricer_config',
	]
	, function (jq, amaselApp,
							mainCtrl, ordersCtrl, productsCtrl,
							purchaseOrdersCtrl, printSettingsCtrl, screenSettingsCtrl, fortuneCookieSettingsCtrl, vatSettingsCtrl,
							reportsCtrl,
							repricerStatusCtrl,
							repricerConfigCtrl
							) {

	console.group("Initializing amaselApp");

	amaselApp.amaselMain.config(['$routeProvider', function($routeProvider) {
		$routeProvider
			.when('/', {templateUrl: 'views/main.html', controller: mainCtrl})
			.when('/orders', {templateUrl: 'views/orders.html', controller: ordersCtrl})
			.when('/products', {templateUrl: 'views/products.html', controller: productsCtrl})
			.when('/purchaseOrders', {templateUrl: 'views/purchase_orders.html', controller: purchaseOrdersCtrl})
			.when('/printSettings/:page', {templateUrl: 'views/print_settings.html', controller: printSettingsCtrl})
			.when('/screenSettings/', {templateUrl: 'views/screen_settings.html', controller: screenSettingsCtrl})
			.when('/fortuneCookieSettings/', {templateUrl: 'views/fortune_cookie_settings.html', controller: fortuneCookieSettingsCtrl})
			.when('/vatSettings/', {templateUrl: 'views/vat_settings.html', controller: vatSettingsCtrl})
			.when('/reports/', {templateUrl: 'views/reports.html', controller: reportsCtrl})
			.when('/repricerStatus', {templateUrl: 'views/repricer_status.html', controller: repricerStatusCtrl})
			.when('/repricerConfigure', {templateUrl: 'views/repricer_config.html', controller: repricerConfigCtrl})
			.otherwise({redirectTo: '/'});
	}]);

	amaselApp.config.load(function(){
		amaselApp.init();
	});

	console.groupEnd();
});
