'use strict'
# Copyright 2007-2012 by James Shelby, shelby (at:) dtsol.com; All rights reserved.

# Handle external routes
class External extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		super Epic, view_nm
		@_checkVersion 'init'
	eventNewRequest: () ->
		delete @contact_us
		delete @Table.Options
	action: (action,params) ->
		r = {page:'NO_MATCH'}
		i = new window.EpicMvc.Issue()
		m = new window.EpicMvc.Issue()
		sub_action= action.split '-'
		switch sub_action[0]
			when 'parse_hash' # Page initially loaded; params.hash
				parts= params.hash.split '-'
				r= switch parts[ 0]
					when ''
						page: 'EMPTY_HASH'
					else
						page: parts[ 0], code: parts[ 1]
			when 'seo' # Page initially loaded; params.hash
				r.url= sub_action[1]
			when 'choose_learn_contact_us'
				@contact_us= true
			else [r, i, m]= super action, params
		[r, i, m]
	loadTable: (tbl_nm) ->
		switch tbl_nm
			when 'Version'
				row=
					current: @version.current
					has_changed: if @version.change is true then 'yes' else''
				@Table[tbl_nm]= [ row ]
			when 'Options'
				row= tab_learn_contact: if @contact_us is true then 'yes' else''
				@Table[tbl_nm]= [ row ]
			when 'Browser'
				[app,ver]= @navigator_browserType()
				row= app:app, ver:ver, is_chrome: if app is "Chrome" then 'yes' else''
				[device,d_ver]= @navigator_deviceType()
				arr= ["iPhone","iPad","Mobile","Android"]
				row.is_mobile= if device in arr then 'yes' else''
				row.device=  if device then device else ''
				row.d_ver= if d_ver then d_ver else ''
				@Table[tbl_nm]= [ row ]
	#TODO THIS ASSUMES KEY AND VALUE HAVE NO DASH!
	encode: (key,value) -> "#{key}-#{value}" # Caller must uri-encode key+value and prefix '#'

	navigator_browserType:->
		N= navigator.appName
		ua= navigator.userAgent
		M= ua.match(/(opera|chrome|safari|firefox|msie)\/?\s*(\.?\d+(\.\d+)*)/i)
		if (M && (tem= ua.match(/version\/([\.\d]+)/i))!= null) then M[2]= tem[1]
		if M then [M[1], M[2]] else [N, navigator.appVersion]
	navigator_deviceType:->
		N= navigator.appName
		ua= navigator.userAgent
		M= ua.match(/(android|mobile|iphone|ipad)\/?\s*(\.?\d+(\.\d+)*)/i)
		if (M && (tem= ua.match(/version\/([\.\d]+)/i))!= null) then M[2]= tem[1]
		if M then [M[1], M[2]] else [N, navigator.appVersion]

	_getVersion: =>
		$.get 'version.txt', _: new Date().getTime(), (data) => @_checkVersion data
	_checkVersion: (data) =>
		if data is 'init'
			@version= current: false, change: false, check: false, terms_use: false, privacy: false
			@_getVersion() # Quickly get current version
			@version.check= setInterval @_getVersion, 1000* 60* 5
		else if typeof data is 'string' and data[0] is '{'
			obj= JSON.parse data
			# Capture these only once (will reset only on reload, so they reflect what user would 'see')
			@version[nm]= obj[nm+'_version'] or false for nm in ['terms_use', 'privacy']
			if @version.current is false
				@version.current= obj.index_html_version or false
				@invalidateTables ['Version']
			else if @version.current isnt obj.index_html_version
				@version.change= true
				@invalidateTables ['Version']
		if @version.change is true and @version.check isnt false
			clearInterval @version.check # Stop checking when we know it changed
			@version.check= false

window.EpicMvc.Model.External= External # Public API
