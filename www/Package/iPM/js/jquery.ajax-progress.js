// https://github.com/englercj/jquery-ajax-progress/blob/master/js/jquery.ajax-progress.js

(function($, window, undefined) {
	// patch ajax settings to call a progress callback
	if (typeof $.browser.msie !== 'undefined' || !$.browser.msie) {
		var oldXHR = $.ajaxSettings.xhr;
		$.ajaxSettings.xhr = function() {
			var xhr = oldXHR();
			if (xhr instanceof window.XMLHttpRequest) {
				if (xhr.addEventListener)  // W3C DOM
					xhr.addEventListener('progress', this.progress, false);
				else if (xhr.attachEvent) { // IE DOM
					xhr.attachEvent('onprogress', this.progress);
				}
			}
			if (xhr.upload) {
				if (xhr.upload.addEventListener)  // W3C DOM
					xhr.upload.addEventListener('progress', this.progress, false);
				else if (xhr.upload.attachEvent) { // IE DOM
					xhr.upload.attachEvent('onprogress', this.progress);
				}
			}
			return xhr;
		};
	}
})(jQuery, window);
