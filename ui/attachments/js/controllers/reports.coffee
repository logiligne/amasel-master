'use strict';
define 'controllers/reports', ['amaselApp'], (amaselApp) ->
	reportsCtrl = ($scope, $interpolate, $routeParams) ->
		$scope.nav.title = "Billing reports"
		$scope.setBillingReports = (reports) =>
			$scope.reports = reports
			if $scope.reports.length > 0
				$scope.currentIndex = $scope.reports.length - 1
				$scope.current = $scope.reports[$scope.currentIndex]
		$scope.setCurrent = (idx) =>
			if idx >=0 and idx < $scope.reports.length
				$scope.currentIndex = idx
			$scope.current = $scope.reports[$scope.currentIndex]
		amaselApp.dbModel.fetchBillingreports($scope)
	amaselApp.amaselMain.controller( 'ReportsCtrl', reportsCtrl);
			
	return reportsCtrl;
		
