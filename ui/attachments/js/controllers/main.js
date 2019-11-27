'use strict';
define(
	'controllers/main'
	, [
		'amaselApp',
	]
	, function (amaselApp) {
			var mainCtrl = function ( $scope, $filter ) {
				$scope.config = amaselApp.config;
				if(!$scope.nav)
					$scope.nav = {};
				$scope.nav.title = 'Summary';
				$scope.nav.loadInProgress = false;
				$scope.nav.inProgress = false;

				$scope.safeApply = function(fn) {
				  var phase = this.$root.$$phase;
				  if(phase == '$apply' || phase == '$digest') {
				    if(fn && (typeof(fn) === 'function')) {
				      fn();
				    }
				  } else {
				    this.$apply(fn);
				  }
				};

				amaselApp.dbModel.inProgressSetter = function(v){
					$scope.safeApply(function(){
						$scope.nav.inProgress = v;
					})
				}
				amaselApp.config.inProgressSetter = amaselApp.dbModel.inProgressSetter

				$scope.setPageSize = function(pageSize){
					$scope.pageSize = pageSize;
				}

				$scope.numPages = function(list){
					if(!list) {
						//console.log('np:null - '+ list);
						return 0;
					}
					//console.log('np:' + list.length +' / ' +$scope.pageSize +' = ' + (list.length/$scope.pageSize) );
					return Math.ceil(list.length / $scope.pageSize);
				}
				$scope.getPage = function(list,page){
					//pager counts from 1
					if(!list){
						//console.log("getPage(list=null)");
						return null;
					}
					//console.log("getPage("+page +"," + $scope.pageSize +")");
					return list.slice((page-1)*$scope.pageSize,(page)*$scope.pageSize);
				}
				$scope.productURL = function(asin){
					if (amaselApp.config.lang == 'DE' ){
						return "http://amazon.de/dp/"  + asin;
					}
					if(amaselApp.config.lang == 'UK'){
						return "http://amazon.co.uk/dp/"  + asin;
					}
					return 'INVALID_LANG'
				}
			};

			amaselApp.amaselMain.controller( 'MainCtrl', mainCtrl );
			return mainCtrl;

	}
)
