'use strict';
define 'controllers/vat_settings', ['amaselApp'], (amaselApp) ->
	vatSettingsCtrl = ($scope, $interpolate, $routeParams) ->
		$scope.nav.title = "VAT Settings"
		$scope.vat = amaselApp.config.vat
		$scope.saveVat = ()=>
			amaselApp.config.save('vat', $scope.vat)

	amaselApp.amaselMain.controller( 'VatSettingsCtrl', vatSettingsCtrl);

	return vatSettingsCtrl;
