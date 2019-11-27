'use strict';
define 'controllers/fortune_cookie_settings', ['amaselApp'], (amaselApp) ->
	fortuneCookieSettingsCtrl = ($scope, $interpolate, $routeParams) ->
		$scope.nav.title = "Fortune Cookie Settings"
		$scope.fortune_cookie = amaselApp.config.fortune_cookie
		$scope.saveFortuneCookie = ()=>
			amaselApp.config.save('fortune_cookie', $scope.fortune_cookie)

	amaselApp.amaselMain.controller( 'FortuneCookieSettingsCtrl', fortuneCookieSettingsCtrl);

	return fortuneCookieSettingsCtrl;
