(function() {
	var port = 0;
	var prefix = 'api/a1.p1.u1.w3/';
	var bt_sandbox = "MIIBCgKCAQEAxvgG3vQzxlFBk+MSO/oMA0M2E8jEy0Wgf2e9M7Mh9PM9ss/2SC3yq/DL9VYHzDHky9VeGcGNVXbVSExub8oQ91hXPAvLXL922y5486/Hk1F3ViiAJuf3aabLw471O84m2vWnftEQx9UrMwub9E31XSvj6oLhIIIWutrx9rClA4PBQTkSUGAYduUof5plbH0n99nNs/Gar/n7KdfRPVBx0HFhPeARlFTVX99jawUGPcgqKEnabo9F6yVjlHhg1VwcvHpEhsA5tRTHmAyZiue/Vl5tG4jWsOwRXeClqlyLhlhOrGiT/m9jjlp+RueHAVIpB1Zx56CJs7EAWzqm6z07PwIDAQAB";
	var bt_production = "MIIBCgKCAQEAkvz76WcdziQrBtFpdmwxQ5oixtgU6qqQtQD47by2DPQgn7ljGnJQYg6cwsiD0+9mlZKagyu+xbTjVobKasvnDbvl5JQAaXu0snvSVouKFvCxd9z50J3Bx64qf/Xt9T+9TP276C79G04x+M4kDKJ9eWu9rPsrVMwg/zUij9nLNpwQgo2gcHYDSincNqIzltPgQMKfEq7dksK+G5F4DL1R3TEzM3CPTI190FIKuPCDceGa6BXlE3jesfdBrn8Sta6/8WFQgi61CKF1iCmIVkRH/6JSmT3YxdYSBd9uC5w8qzAE1pJaDOZ2O6bKSawV23gw4O7pdvGVW/kbwCkOrP5wrwIDAQAB";
	if (port) {
		// JCS: TALK TO STAGE FROM NON-DEPLOYED CODE TO DEBUG ISSUES
		if (0) {
			window.EpicMvc.Extras.options = {
	    		RestEndpoint : 'https://api-stage.iprojectmobile.com/'+ prefix,
	    		PollEndpoint : 'https://poll-stage.iprojectmobile.com/'+ prefix,
	    		UploadEndpoint : 'https://upload-stage.iprojectmobile.com/'+ prefix
				,BtEncKey: bt_sandbox
			};
		} else {
			window.EpicMvc.Extras.options = {
	    		RestEndpoint : 'http://epic.dv-mobile.com:90' + port + '/'+ prefix,
	    		PollEndpoint : 'http://epic.dv-mobile.com:90' + port + '/'+ prefix,
	    		UploadEndpoint : 'http://epic.dv-mobile.com:92' + port + '/'+ prefix
				,BtEncKey: bt_sandbox
			};
		}
	} else {
		var full = window.location.host;
		var parts = full.split('.');
		var sub = parts[0];
		if (sub === "dev") {
			window.EpicMvc.Extras.options = {
				RestEndpoint : 'http://api-dev.iprojectmobile.com/' + prefix,
				PollEndpoint : 'http://poll-dev.iprojectmobile.com/' + prefix,
				UploadEndpoint : 'http://upload-dev.iprojectmobile.com/' + prefix,
				BtEncKey : bt_sandbox
			};
		} else if (sub === "demo") {
			window.EpicMvc.Extras.options = {
				RestEndpoint : 'https://api-dev.iprojectmobile.com/' + prefix,
				PollEndpoint : 'https://poll-dev.iprojectmobile.com/' + prefix,
				UploadEndpoint : 'https://upload-dev.iprojectmobile.com/' + prefix,
				BtEncKey : bt_sandbox
			};
		} else if (sub === "stage") {
			window.EpicMvc.Extras.options = {
				RestEndpoint : 'https://api-stage.iprojectmobile.com/' + prefix,
				PollEndpoint : 'https://poll-stage.iprojectmobile.com/' + prefix,
				UploadEndpoint : 'https://upload-stage.iprojectmobile.com/' + prefix,
				BtEncKey : bt_sandbox
			};
		} else if (sub === "prod") {
			window.EpicMvc.Extras.options = {
				RestEndpoint : 'https://api-prod.iprojectmobile.com/' + prefix,
				PollEndpoint : 'https://poll-prod.iprojectmobile.com/' + prefix,
				UploadEndpoint : 'https://upload-prod.iprojectmobile.com/' + prefix,
				BtEncKey : bt_production
			};
		} else {
			window.EpicMvc.Extras.options = {
				RestEndpoint : 'https://api.iprojectmobile.com/' + prefix,
				PollEndpoint : 'https://poll.iprojectmobile.com/' + prefix,
				UploadEndpoint : 'https://upload.iprojectmobile.com/' + prefix,
				BtEncKey : bt_production
			};
		}
	}
})();
