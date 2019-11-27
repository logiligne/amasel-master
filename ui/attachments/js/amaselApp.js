"use strict";
define(
	'amaselApp'
	, [
		'jquery', // needed by angular-ui
		'select2',
		'angular',
		'angular-sanitize',
		'angular-ui',
		'angular-bootstrap',
		'dbModel',
		'appConfig',
	]
	, function (jquery, sel2, notAngular, notAngSanitize, notAngularUI ,notAngularUIBootstrap ,dbModel, appConfig) {
		  var angularModule = angular.module('AmaselMain', ['ngSanitize','ui','ui.bootstrap'])
		 			,app = {}

			app.init = function init() {
				//using global angular var
				angular.bootstrap(document, ['AmaselMain']);
			}

			app.dbModel = dbModel
			app.config = appConfig;

		 	app.__defineGetter__('amaselMain', function() {return angularModule;})

		 	return app;

	 }
);
