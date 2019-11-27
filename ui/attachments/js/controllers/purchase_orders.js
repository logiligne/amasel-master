'use strict';
define(
	'controllers/purchase_orders'
	, ['amaselApp']
	, function (amaselApp) {
		  
			var purchaseOrdersCtrl = function ($scope, $filter, $window) {
				amaselApp.dbModel.fetchProducts($scope);
				amaselApp.dbModel.fetchPurchaseOrders($scope);
				$scope.nav.title = "Purchase Orders";
				$scope.numColumns = 6;
		    $scope.rows = [];
		    $scope.cols = []; 

				$scope.log = function(o){
					console.log("log:",o);
					return '';
				}

				$scope.setProductsBySKU = function(products){
					$scope.productsBySKU = products;
				}
				
				$scope.setPurchaseOrders = function(purchaseOrders){
					$scope.purchaseOrders = purchaseOrders;
					for(var i in $scope.purchaseOrders){
						var item = $scope.productsBySKU[$scope.purchaseOrders[i].SKU];
						$scope.purchaseOrders[i].item = item;
					}
					$scope.ordered = $scope.purchaseOrders;
					var len = $scope.ordered ? $scope.ordered.length : 0;
			    $scope.rows.length = Math.ceil(len / $scope.numColumns);
			    $scope.cols.length = $scope.numColumns; 
				}
				
				$scope.getColumns = function(list, row){
					return list.slice(row* $scope.numColumns,(row+1)*  $scope.numColumns);
				}

				$scope.setQuantity = function(sku,quantity){
					amaselApp.dbModel.savePurchaseOrder(sku,quantity,function(){
						amaselApp.dbModel.fetchPurchaseOrders($scope);
					});
				}
				$scope.deleteAll = function(){
					amaselApp.dbModel.deleteAllFromView('purchase_orders',function(){
						amaselApp.dbModel.fetchPurchaseOrders($scope);
					});
				}
				
				$scope.startEdit = function(o){
					o._editing = true;
					o._Quantity = o.Quantity;
				}
				
				$scope.saveEdit = function(o){
					$scope.setQuantity(o.SKU,o.Quantity);
					o._editing = null;
				}
				
				$scope.cancelEdit = function(o){
					o._editing = null;
				}
				
				$scope.print = function(){
					$window.print();
				}
			};
			
			amaselApp.amaselMain.controller( 'PurchaseOrdersCtrl', purchaseOrdersCtrl);
			
			return purchaseOrdersCtrl;
		
	}
)