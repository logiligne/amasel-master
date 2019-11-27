'use strict';
define 'controllers/screen_settings', ['amaselApp'], (amaselApp) ->
	screenSettingsCtrl = ($scope, $interpolate, $routeParams) ->
		$scope.nav.title = "Screen Settings"
		$scope.screenPageSize = amaselApp.config.screenPageSize
		$scope.saveScreenPageSize = ()=>
			amaselApp.config.save('screenPageSize', $scope.screenPageSize)
			
	amaselApp.amaselMain.controller( 'ScreenSettingsCtrl', screenSettingsCtrl);
			
	return screenSettingsCtrl;
		
