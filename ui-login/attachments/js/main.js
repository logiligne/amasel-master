"use strict";

define(
	'main'
	, [
		'jquery',
	]
	, function ($) {
		var btnSel = '#login_button',
				errMsgSel = '#error_messages',
				relRedirect = false;
	
		var startSpin = function(){
			$(btnSel).prepend('<img src="img/ajax-loader.gif" style="margin: 0 5px 0 0;">')
				.attr('disabled','disabled');
		}
		var endSpin = function(error){
			if(error != null){
				$(errMsgSel).show().text(error);
			} else {
				$(errMsgSel).hide().text();
			}
			$(btnSel).removeAttr('disabled').children('img').remove();
		}
	
		$(btnSel).click(function(){
			console.log("Start login");
			var loginData = {
				name : $('#username').val(),
				password : $('#password').val(),
			}
			var selfUrl = 
				window.location.protocol + '//' 
				+ 
				window.location.host + window.location.pathname;
			
			if(selfUrl[selfUrl.length-1] != '/'){
				selfUrl += '/';
			}
			startSpin();
			$.ajax({
			  type: "POST",
			  url: selfUrl + 'session',
				contentType: 'application/json',
			  data: JSON.stringify(loginData),
			  dataType: "json",
			}).done(function(data,textStatus, jqXHR){
				if(data.ok != true){
					endSpin("Login failed for unknown reason.");
					return;
				}
				$.ajax({
				  url: selfUrl + 'users/org.couchdb.user:' + loginData.name,
					contentType: 'application/json',
				  dataType: "json",
				}).done(function(data,textStatus, jqXHR){
					endSpin();
					// Redirect here
					if(relRedirect){
						window.location = selfUrl + data.amasel.defaultDatabase + '/';
					} else {
						window.location = '/' + data.amasel.defaultDatabase + '/';
					}
				}).fail(function(jqXHR, textStatus, errorThrown){
					endSpin('Failed to get user settings!');
				});
			}).fail(function(jqXHR, textStatus, errorThrown){
				var err;
				if( jqXHR.status == 401) {
					err = 'Invalid user or password';
				} else {
					err= 'Failed to connect';
				}
				endSpin(err);
			});
			return false;
		});

});