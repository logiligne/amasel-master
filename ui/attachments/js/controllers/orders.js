'use strict';
define(
	'controllers/orders'
	, [
		'amaselApp',
		'print/pdfmake_print',
		'print/hflow_layout',
		'print/dimUnit',
		'print/dimBox',
	]
	, function (amaselApp, pdfPrinter, HFlowLayout,  DimUnit, DimBox) {

			var ordersCtrl = function ($scope, $filter, $dialog, $interpolate) {
				$scope.nav.title = "Orders";
				amaselApp.dbModel.fetchOrders($scope);
				amaselApp.dbModel.fetchProducts($scope);
				$scope.setPageSize( amaselApp.config.screenPageSize );
				$scope.orders = [];
				$scope.filtered = [];
				$scope.currentPage = 1;
				$scope.numberOfPages = 0;
				$scope.toggleSelected = false;
				$scope.selectNoneDummy = false;
				$scope.selectAllDummy = true;
				$scope.selected = {};

				$scope.flags = ['Need address', 'Wait for answer', 'Shipping confirmed'];
				$scope.flagFilters = ['No flags','All'].concat($scope.flags);
				$scope.filterByFlag = $scope.flagFilters[0];

				$scope.doFilter  = function() {
					var filtered = $filter('filter')($scope.orders, $scope.query);
					var filteredByFlag = [];
					//console.log("FilterbyFlagL",$scope.filterByFlag);

					if($scope.filterByFlag == 'No flags'){
						for(var i in filtered){
							var order = filtered[i];
							if(order.flags == null || order.flags.length == 0){
								filteredByFlag.push( order );
							}
						}
					} else if($scope.filterByFlag == 'All'){
						filteredByFlag = filtered;
					} else {
						for(var i in filtered){
							var order = filtered[i];
							if(order.flags && order.flags.indexOf($scope.filterByFlag) >= 0){
								filteredByFlag.push( order );
							}
						}
					}
					$scope.currentPage = 1;
					$scope.filtered = filteredByFlag;
					$scope.numberOfPages = $scope.numPages($scope.filtered);
				}

				$scope.setOrders = function(orders){
					$scope.currentPage = 1;
					$scope.orders = orders;
					for(var i in $scope.orders){
						var order = $scope.orders[i];
						if(order.flags){
							order.saveFlags  = order.flags.slice(0);
						}
					}
					$scope.doFilter();
				}

				$scope.setProductsBySKU = function(productsBySKU){
					$scope.productsBySKU = productsBySKU;
				}


				$scope.$watch('query',function(){
					$scope.doFilter();
				});

				$scope.$watch('filterByFlag	',function(){
					$scope.doFilter();
				});

				$scope.amazonOrderUrl= 'https://sellercentral.amazon.de/gp/orders-v2/details/ref=ag_orddet_cont_myo?ie=UTF8&orderID='

				var flagsEmpty = function(flags){
					if(Array.isArray(flags)){
						var e = (flags.indexOf("")>=0)? 1:0;
						return flags.length == e;
					} else if(flags==""){
						return true;
					} else if(flags==null || flags==undefined){
						return true;
					}
					return falsel
				}
				$scope.flagsChange = function(order){
					var of = flagsEmpty(order.flags) ? [] : order.flags;
					var sf = flagsEmpty(order.saveFlags) ? [] :order.saveFlags;
					var modified = !angular.equals(of, sf);
					if(modified){
						//console.log("Saving flags:",order.saveFlags.slice(0));
						order.flags = order.saveFlags.slice(0);
						amaselApp.dbModel.saveFlags(order.AmazonOrderId);
					}
				}

				$scope.confirmShipping = function(){
					var scFlag = "Shipping confirmed";
					var ordList = [];
					for(var i in $scope.filtered){
							var o = $scope.filtered[i];
							if(!$scope.selected[o.AmazonOrderId]){
									continue;
							}
							if (!flagsEmpty(o.flags) && o.flags.indexOf(scFlag)>=0 ){
								continue;
							}
							if (!o.flags) {
								o.flags = []
							}
							o.flags.push("Shipping confirmed");
							ordList.push( o.AmazonOrderId );
					}
					amaselApp.dbModel.saveFlags( ordList, function(err){
						if(err){
							return;
						}
						$scope.selectNone();
						$scope.refresh();
					});
				}

				$scope.refresh = function(){
					amaselApp.dbModel.fetchOrders($scope);
				}

		    $scope.orderDetails = function(order){
	        var d = $dialog.dialog({
						modalFade: false,
						resolve: {
							order: order ,
							pbySKU: $scope.productsBySKU,
						}
					});
					var ctrl = function($scope, order,pbySKU){
						$scope.order= order;
						$scope.pbySKU = pbySKU;
						$scope.close = function(){
							d.close();
						}
					}
	        d.open('views/order_details.html',ctrl);
		    };

				$scope.$watch('toggleSelected',function(){
					var cp = $scope.getPage($scope.filtered,$scope.currentPage);
					for(var i in cp){
						var o = cp[i];
						$scope.selected[o.AmazonOrderId] = !$scope.selected[o.AmazonOrderId];
					}
				});

				$scope.$watch('selectAllDummy', function() {
					var cp = $scope.getPage($scope.filtered,$scope.currentPage);
					for(var i in cp){
						var o = cp[i];
						$scope.selected[o.AmazonOrderId] = true;
					}
				  $scope.selectNoneDummy = false;
				  $scope.selectAllDummy = true;
				});

				$scope.selectNone = function() {
					var cp = $scope.getPage($scope.filtered,$scope.currentPage);
					for(var i in cp){
						var o = cp[i];
						$scope.selected[o.AmazonOrderId] = false;
					}
				  $scope.selectNoneDummy = false;
				  $scope.selectAllDummy = true;
				};

				$scope.$watch('selectNoneDummy', $scope.selectNone);


				$scope.printDialog = function(){

					var skipLabelsPreview = function(profile){
						var cfg = angular.copy(amaselApp.config);
						cfg.pageOptions = amaselApp.config.printSettings[profile].pageOptions;
						cfg.labelsOptions = amaselApp.config.printSettings[profile].labelsOptions;

						var pageBox = new DimBox(cfg.pageOptions)
						var labelBox = new DimBox(cfg.labelsOptions);
						var labelsPerPage = HFlowLayout.numObjectsPerPage(pageBox, labelBox,cfg.labelsOptions.labelHorizontalSpacing,cfg.labelsOptions.labelVerticalSpacing)
						var labels = [];
						for(var i =0; i < labelsPerPage ;++i){
							labels.push(i);
						}
						var opts = cfg.labelsOptions;
			 			var pageWidth = pageBox.width.v;
			 			var labelWidth = labelBox.width.convert(pageBox.width.u).v;
			 			var labelSpace = new DimUnit(opts.labelHorizontalSpacing).convert(pageBox.width.u).v;
			 			var c = (labelWidth+labelSpace)/pageWidth;
						return {
							labels: labels,
							labelWidthPerc: c*100,
						}
					}

					var printProfiles = {};
					for(var i in amaselApp.config.printSettings){
						printProfiles[i] = amaselApp.config.printSettings[i];
					}

	        var d = $dialog.dialog({
						modalFade: false,
						resolve: {
							parentData :{
								getPage: $scope.getPage,
								orders: $scope.orders,
								filtered: $scope.filtered,
								selected: $scope.selected,
								currentPage : $scope.currentPage,
								useProfile: amaselApp.config.currentPrintProfile,
								printProfiles: printProfiles,
							}
						}
					});

					var ctrl = function($scope, parentData){
						angular.extend($scope, parentData);
						angular.extend($scope,skipLabelsPreview($scope.useProfile));
						$scope.printType = "page";
						$scope.$watch('useProfile',function(){
							angular.extend($scope,skipLabelsPreview($scope.useProfile));
						});

						$scope.setSkip = function(skip){
							$scope.skipLabels=skip;
						}
						$scope.close = function(){
							d.close();
						}
						$scope.print = function(){
							var ordList;
							if($scope.printType === "page"){
									ordList = $scope.getPage($scope.filtered,$scope.currentPage);
							} else if($scope.printType === "all"){
									ordList = $scope.filtered;
							} else if($scope.printType === "selected"){
									ordList = [];
									for(var i in $scope.filtered){
											var o = $scope.filtered[i];
											if($scope.selected[o.AmazonOrderId]){
													ordList.push( o );
											}
									}
							} else {
									alert("??? Something wrong. Please refresh page. ");
							}
							var profile = $scope.useProfile;
							var cfg = angular.copy(amaselApp.config);
							cfg.pageOptions = amaselApp.config.printSettings[profile].pageOptions;
							cfg.labelsOptions = amaselApp.config.printSettings[profile].labelsOptions;
							cfg.currentPrintProfile = profile;
							console.log($scope.orders);
							console.log(ordList);
							(new pdfPrinter(cfg)).renderLabels(ordList, function(blobURL){
								var newWin = window.open('about:blank', 'Print');
								var minHeight =  document.documentElement.clientHeight - 50;
								newWin.document.write(
									`<!DOCTYPE html>
									<html lang="en">
									<head>
										<title>Amasel Print</title>
									</head>
									<script>
										function doPrint(){
											var getMyFrame = document.getElementById("pdf-print");
											getMyFrame.focus();
											getMyFrame.contentWindow.print();
										}
									</script>
									<body>
										<div><button onclick="doPrint()" style="float: right;">Print</button></div>
										<iframe id="pdf-print" src="${blobURL}" width="100%" height="100%" style="min-height: ${minHeight}px;" >
									</body>
									</html>
									`
								)
							});
							$scope.close();
						}
					}
	        d.open('views/print_labels.html',ctrl);

				};
			};

			amaselApp.amaselMain.controller( 'OrdersCtrl', ordersCtrl);

			return ordersCtrl;

	}
)
