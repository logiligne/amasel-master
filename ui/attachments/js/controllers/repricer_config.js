'use strict';
define(
	'controllers/repricer_config'
	, ['amaselApp']
	, function (amaselApp) {

			var repricerConfigCtrl = function ($scope, $filter) {
				amaselApp.dbModel.fetchProducts($scope,{withRepricerConfig:true});
				$scope.nav.title = "Repricer config";
				$scope.setPageSize(50);
				$scope.filtered = [];
				$scope.currentPage 	= 1;
				$scope.numColumns = 1;
		    $scope.rows = [];
		    $scope.cols = [];
				$scope.searchInSKU = true;
				$scope.searchInASIN = false;
				$scope.searchInTitle = false;
				$scope.searchActive = false;
				$scope.searchInactive = false;
				$scope.limit = $scope.pageSize;

				$scope.doFilter = function() {
					var q = $scope.query;
					if((q && q.length>0) || $scope.searchActive || $scope.searchInactive){
						q = new RegExp(q,'i');
						$scope.filtered = $filter('filter')($scope.products, function(obj){
							//console.log(obj);
							if($scope.searchActive && (!obj.repricer || (obj.repricer.active != true))  ) {
								return false;
							}
							if($scope.searchInactive && obj.repricer && obj.repricer.active == true) {
								return false;
							}
							if($scope.searchInSKU && obj.SKU && (obj.SKU.search(q) == 0)){
								//console.log("in sku" + obj.SKU);
								return true;
							}
							if($scope.searchInASIN && obj.ASIN && (obj.ASIN.search(q) == 0)){
								//console.log("in ASIN");
								return true;
							}
							if($scope.searchInTitle && obj.title && (obj.title.search(q) >=0)){
								//console.log("in title");
								return true;
							}
							return false;
						});
					}else {
						$scope.filtered = $scope.products;
					}
					$scope.filtered = $filter('orderBy')($scope.filtered,function(obj) { return parseFloat(obj.Price);});
					$scope.currentPage = 1;
					var len = $scope.filtered ? $scope.filtered.length : 0;
					if(len > $scope.pageSize){
						len = $scope.pageSize;
					}
			    $scope.rows.length = Math.ceil(len / $scope.numColumns);
			    $scope.cols.length = $scope.numColumns;
				}

				$scope.setProducts = function(products){
					$scope.products = products;
					$scope.doFilter();
				}

				$scope.priceInvalid = function(price){
					price = parseFloat(price);
					return isNaN(price) || (price <= 0);
				}

				$scope.getColumns = function(list, page, row){
					return $scope.getPage(list,page).slice(row* $scope.numColumns,(row+1)*  $scope.numColumns);
				}

				$scope.saveRepriceConfig = function(sku,config){
					amaselApp.dbModel.saveRepriceConfig(sku,config);
				}

				$scope.timeoutID = null;
				var refilter = function(){
					if($scope.timeoutID){
						clearTimeout($scope.timeoutID);
					}
					$scope.timeoutID = setTimeout(function(){
						$scope.$apply(function(){
							$scope.doFilter();
							$scope.timeoutID = null;
						});
					},300);
				};
				$scope.$watch('query', refilter);
				$scope.$watch('searchInSKU', refilter);
				$scope.$watch('searchInASIN', refilter);
				$scope.$watch('searchInTitle', refilter);
				$scope.$watch('searchActive', refilter);
				$scope.$watch('searchInactive', refilter);

			};

			amaselApp.amaselMain.controller( 'RepricerConfigCtrl', repricerConfigCtrl);

			return repricerConfigCtrl;

	}
)
