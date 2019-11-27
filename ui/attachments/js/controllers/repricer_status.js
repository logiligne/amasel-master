'use strict';
define(
	'controllers/repricer_status'
	, ['amaselApp']
	, function (amaselApp) {

			var repricerStatusCtrl = function ($scope, $filter) {
				amaselApp.dbModel.fetchProducts($scope);
				amaselApp.dbModel.fetchRepricerHistory($scope);
				$scope.nav.title = "Repricer status";
				$scope.setPageSize(50);
				$scope.history = [];
				$scope.historyFull = [];
				$scope.currentPage = 1;
				$scope.numColumns = 1;
		    $scope.rows = [];
		    $scope.cols = [];
				$scope.limit = $scope.pageSize;
				$scope.detailed = false;

				$scope.filterDetailed = function() {
					if($scope.detailed) {
						$scope.history = $scope.historyFull;
						$scope.rows.length = history.length;
					} else {
						var filtered = [];
						for(var i in $scope.historyFull){
							var obj = $scope.historyFull[i];
							if (obj.newPrices.length > 0){
								filtered.push(obj);
							}
						}
						$scope.history = filtered;
						$scope.rows.length = history.length;
					}
					console.log("------", $scope.history.length, $scope.historyFull.length)
					$scope.currentPage = 1;
				}
				$scope.setRepricerHistory = function(history){
					console.log(" setRepricerHistory ", history);
					$scope.historyFull = history;
					$scope.filterDetailed();
				}
				$scope.setProductsBySKU = function(productsBySKU) {
					$scope.productsBySKU = productsBySKU;
				}

				$scope.getColumns = function(list, page, row){
					return $scope.getPage(list,page).slice(row* $scope.numColumns,(row+1)*  $scope.numColumns);
				}
				$scope.$watch('detailed', $scope.filterDetailed);

			};

			amaselApp.amaselMain.controller( 'RepricerStatusCtrl', repricerStatusCtrl);

			return repricerStatusCtrl;

	}
)
