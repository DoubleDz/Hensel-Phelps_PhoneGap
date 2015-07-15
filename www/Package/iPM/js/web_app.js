$(window).on("resize", setup_web_app_view);

function ipm_content_update(el) {
	// TODO: make it possible to attach to a specific dom element "el"
	// For now we're just setting up all selectors for web app view
	setup_web_app_view(null, el);
};

function setup_web_app_view(evt, el) {
	var width = $(window).width();
	if (el == null) {
		el = $('body');
	}
	if (width >= 1200) {
		$('#ipm-main-content', el).addClass('span9');
		$('#ipm-right-sidebar', el).addClass('span3');
		$('.right-widget-container', el).removeClass('span12');
		$('.activity-container', el).removeClass('span6');
		$('.team-container', el).removeClass('span6');
	} else if (width >= 768 && width < 1200) {
		$('#ipm-main-content', el).removeClass('span9');
		$('#ipm-right-sidebar', el).removeClass('span3');
		$('.right-widget-container', el).addClass('span12');
		$('.activity-container', el).addClass('span6');
		$('.team-container', el).addClass('span6');
	}
}

function setup_home_page() {
	var height = Number($(window).height());
	if ($(window).width() > 640) {
		$('.full-screen-page').each(function() {
			$(this).css("height", (height - 24));
		});
	}
	$('.first-full-screen-page').first().css("height", (height - 24));	
}

// Separate this function from setup_view, and call it for new content
// Note: currently this part already has this functionality:
// ./view/part/file_folder_js.part.html
function folder_file_rollovers() {
	// Shows and hides the action panes for each row in the center of the
	// web-client (Team,Actions,Annotations,etc)
	$('.row.public-row,.row.private-row,.row.file-row').hover(function() {
		$(".action-pane", this).addClass('active');
	}, function() {
		if (!$(this).find('li.active').length) {
			$(".action-pane", this).removeClass('active');
		}
	});
}

function setup_spinner(sel, text_value) {
	var txt = (typeof text_value != 'undefined') ? ' ' + text_value : '';
	var out_html = '<img src="Package/iPM/images/loading.gif" /> &nbsp; ' + txt;
	$(sel).mousedown(function() {
		var $e = $(this);
		$e.html(out_html);
		setTimeout(function() {
			$e.click();
		}, 100);
	});
	$(sel).keydown(function(e) {
		if (e.which == 32 || e.which == 13) {
			$(this).html(out_html);
			return true;
		}
	});
}

function get_my_position(obj, v_offset, h_offset) {
	if (typeof v_offset == 'undefined') {
		var v_offset = 0;
	}
	if (typeof h_offset == 'undefined') {
		var h_offset = 6;
	}
	var obj = $(obj);
	var position = obj.parent().offset();
	var top_offset = position.top + v_offset - $(window).scrollTop();
	var left_offset = position.left + h_offset;
	obj.attr('style', 'position:fixed; top:' + top_offset + 'px; left:' + left_offset + 'px;');
}

function user_filter(e, sel) {
	var elem = $(e);
	var match_text = elem.val();
	if (match_text.length) {
		var match_regexp = new RegExp('' + match_text + '+', 'i');
		$(sel).each(function(ix, h_item) {
			var item = $(h_item);
			if (match_regexp.test(item.text()))
				item.show();
			else
				item.hide();
		});
	}
}

function input_filter(val, jq_containers_selector, separator_char, default_show_all) {
	var match_text = val; // TODO Fix issue where user's input has regexp special chars
	if (default_show_all !== false) {
		default_show_all = true;
	}
	if (match_text.length) {
		var match_regexp = new RegExp('' + match_text + '+', 'i');
	}
	$(jq_containers_selector).each(function(ix, dom_item) {
		var item = $(dom_item);
		var show = false
		if (match_text.length) {
			var data = item.attr('data-filter');
			$.each(data.split(separator_char), function(iix, data_field) {
				if (match_regexp.test(data_field)) {
					show = true;
					return false; // break-each
				}
			});
		} else {
			show = default_show_all;
		}
		if (show)
			item.show();
		else
			item.hide();
	});
}

function preload_images(arrayOfImages) {
	$(arrayOfImages).each(function() {
		$('<img />').attr('src', this).appendTo('body').css('display', 'none');
	});
}