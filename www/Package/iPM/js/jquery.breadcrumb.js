/**
 * @author Jason Roy for CompareNetworks Inc. Thanks to mikejbond for suggested updates Version 1.1 Copyright (c) 2009 CompareNetworks Inc. Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
 * 
 * Verson 1.2 - extended by John Cornett
 */
(function($) {
	
	// Private variables
	
	var _options = {};
	var _container = {};
	var _breadCrumbElements = {};
	
	// Public functions
	
	jQuery.fn.jBreadCrumb = function(options) {
		_options = $.extend({}, $.fn.jBreadCrumb.defaults, options);
		
		return this.each(function() {
			_container = $(this);
			setupBreadCrumb();
		});
		
	};
	
	// Private functions
	
	function setupBreadCrumb() {
		_options.totalWidthMax = $(_container).width();
		
		// The reference object containing all of the breadcrumb elements
		_breadCrumbElements = $(_container).find('li');
		
		// Keep it from overflowing in ie6 & 7
		$(_container).find('ul').wrap('<div style="overflow:hidden; position:relative;  width: ' + $(_container).css("width") + ';"><div>');
		// Set an arbitrary width width to avoid float drop on the animation
		$(_container).find('ul').width(5000);
		
		// If the breadcrumb contains nothing, don't do anything
		if (_breadCrumbElements.length > 0) {
			
			$(_breadCrumbElements[0]).addClass('first');
			
			if (_breadCrumbElements.length > 1) {
				$(_breadCrumbElements.last()).addClass('last');
			}
			// If the breadcrumb object length is long enough, compress.
			if (_breadCrumbElements.length > _options.minimumCompressionElements) {
				compressBreadCrumb();
			};
		};
	};
	
	function compressBreadCrumb() {

		// If an alternate home icon or graphic is specified, show it.
		if (_options.home_icon) {
			// If compressing elements, show only the home icon
			$(_breadCrumbElements[0]).find('a').html(_options.home_icon);
		}

		var totalWidth = 0;
		$(_breadCrumbElements).each(function() { totalWidth += $(this).width(); });
		if (totalWidth <= $(_container).width()) {
			return;
		}
		
		// First we check to make sure things will fit
		var totalCompressedWidth = ((_breadCrumbElements.length - _options.endElementsToLeaveOpen) * (_options.previewWidth + 10));
		var i = parseInt(_options.endElementsToLeaveOpen, 10) * -1;
		while (i < 0) {
			el = $(_breadCrumbElements).get(i);
			totalCompressedWidth += $(el).width();
			i++;
		}
		
		// If not, we only show the last element
		if (totalCompressedWidth > $(_container).width()) {
			_options.endElementsToLeaveOpen = 1;
		}
		
		// Get the difference for compressing parents
		var itemsToHide = (_breadCrumbElements.length - _options.endElementsToLeaveOpen);
		
		// We reset the counter to recalculate in the foreach loop below in case we need to slide the whole UL to the left
		totalCompressedWidth = 0;
		
		// We compress only elements determined by the formula setting below
		$(_breadCrumbElements).each(function(i, listElement) {
			if (i > _options.beginingElementsToLeaveOpen && i < itemsToHide) {
				
				$(listElement).find('a').wrap('<span></span>').width($(listElement).find('a').width() + 10);
				
				var options = {
				    id : i,
				    width : $(listElement).width(),
				    listElement : $(listElement).find('span'),
				    isAnimating : false,
				    element : $(listElement).find('span')
				
				};
				
				$(listElement).bind('mouseover', options, expandBreadCrumb).bind('mouseout', options, shrinkBreadCrumb);
				$(listElement).find('a').unbind('mouseover', expandBreadCrumb).unbind('mouseout', shrinkBreadCrumb);
				
				listElement.autoInterval = setInterval(function() {
					clearInterval(listElement.autoInterval);
					$(listElement).find('span').animate({
						width : _options.previewWidth
					}, _options.timeInitialCollapse, _options.easing);
				}, (150 * (i - 2)));
				
				totalCompressedWidth += _options.previewWidth + 10;
			} else {
				totalCompressedWidth += $(listElement).width();
			}
			
		});
		
		// If the overall width won't fit...slide the whole thing left
		if (totalCompressedWidth > _options.totalWidthMax) {
			_container.find('ul').animate({
				marginLeft : -(totalCompressedWidth - _options.totalWidthMax)
			}, _options.timeInitialCollapse, _options.easing);
			$(_breadCrumbElements[0]).css({
			    'position' : 'absolute',
			    'left' : 0,
			    'z-index' : 99,
			    'background-color' : '#FFF'
			});
		}
		
	};
	
	function expandBreadCrumb(e) {
		$(e.data.element).stop();
		$(e.data.element).animate({
			width : e.data.width
		}, {
		    duration : _options.timeExpansionAnimation,
		    easing : _options.easing,
		    queue : false
		});
		return false;
		
	};
	
	function shrinkBreadCrumb(e) {
		$(e.data.element).stop();
		$(e.data.element).animate({
			width : _options.previewWidth
		}, {
		    duration : _options.timeCompressionAnimation,
		    easing : _options.easing,
		    queue : false
		});
		return false;
	};
	
	// Public global variables
	$.fn.jBreadCrumb.defaults = {
	    totalWidthMax : 325,
	    minimumCompressionElements : 1,
	    endElementsToLeaveOpen : 2,
	    beginingElementsToLeaveOpen : 0,
	    timeExpansionAnimation : 200,
	    timeCompressionAnimation : 100,
	    timeInitialCollapse : 5,
	    easing : 'swing',
	    previewWidth : 30,
	    home_icon: false
	};
	
})(jQuery);
