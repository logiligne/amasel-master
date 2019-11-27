'use strict';
define(
	'controllers/products'
	, ['amaselApp']
	, function (amaselApp) {
		  
			var productsCtrl = function ($scope, $filter) {
				amaselApp.dbModel.fetchProducts($scope);
				$scope.nav.title = "Products";
				$scope.setPageSize( 50);
				$scope.filtered = [];
				$scope.currentPage = 1;
				$scope.numColumns = 4;
		    $scope.rows = [];
		    $scope.cols = []; 
				$scope.searchInSKU = true;
				$scope.searchInASIN = false;
				$scope.searchInTitle = false;
				$scope.limit = $scope.pageSize;

				$scope.doFilter = function() {
					var q = $scope.query;
					if(q && q.length>0 ){
						q = new RegExp(q,'i');
						$scope.filtered = $filter('filter')($scope.products, function(obj){
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
					$scope.filtered = $filter('orderBy')($scope.filtered,function(obj) { return parseInt(obj.Quantity);});
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

				$scope.getColumns = function(list, page, row){
					return $scope.getPage(list,page).slice(row* $scope.numColumns,(row+1)*  $scope.numColumns);
				}
				
				$scope.addToPurchaseOrder = function(sku,quantity){
					amaselApp.dbModel.savePurchaseOrder(sku,quantity);
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

				
				
			};
			
			amaselApp.amaselMain.controller( 'ProductsCtrl', productsCtrl);
			
			return productsCtrl;
		
	}
)
