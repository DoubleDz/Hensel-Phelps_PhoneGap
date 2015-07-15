class Rest
	@localCache: -> window.EpicMvc.Extras.localCache
	@rest_url: window.EpicMvc.Extras.options.RestEndpoint
	@rest_upload_url: window.EpicMvc.Extras.options.UploadEndpoint
	@statusCode= true # Assume we were good last time
	@token: false
	@refresh_timer= false
	@auth_user: false
	@auth_web_client: 'web-client'
	@counter= 0

	# All pulldown/db-id-to-text maps for human consumption
	@choices_cache= false
	# Bit flags
	@PERM_ADD_PROJECTS: 1
	@choices: () ->
		f= 'E:Rest.choices'
		#_log2 f, @choices_cache
		return @choices_cache if @choices_cache
		# TODO GET FROM API @choices= @rest.get 'Choices', f
		@choices_cache=
			global:
				disposal:
					0: token: 'active',   nice: 'Active'
					1: token: 'deleted',  nice: 'Deleted'
					2: token: 'purge',    nice: 'Purge'
			members:
				invited_as:
					0:  token: 'member',  nice: 'Member'
					10: token: 'manager', nice: 'Manager'
					20: token: 'owner',   nice: 'Owner'
					30: token: 'watcher', nice: 'Watcher'
					40: token: 'admin',   nice: 'Admin'
			users:
				level:
					0:  sort:  0, type: 'free',  token: 'free',        		nice: 'Restricted'   		,perm: 0
					4:  sort:  1, type: 'pay',   token: 'starter',     		nice: 'Free'         		,perm: 0
					1:  sort:  2, type: 'pay',   token: 'limited',     		nice: 'Starter'      		,perm: 0
					2:  sort:  3, type: 'pay',   token: 'standard',    		nice: 'Standard'     		,perm: @PERM_ADD_PROJECTS
					3:  sort:  4, type: 'pay',   token: 'professional',		nice: 'Professional' 		,perm: @PERM_ADD_PROJECTS
					5:  sort:  5, type: 'adam',  token: 'super',       		nice: 'Super User'   		,perm: @PERM_ADD_PROJECTS
					6:  sort:  6, type: 'parent',token: 'team_owner',  		nice: 'Owner'   			,perm: @PERM_ADD_PROJECTS
					7:  sort:  7, type: 'child', token: 'team_member', 		nice: 'Member'  			,perm: 0
					8:  sort:  8, type: 'child', token: 'team_manager',		nice: 'Project Manager' 	,perm: 0
					9:  sort:  9, type: 'child', token: 'team_creator',		nice: 'Project Creator' 	,perm: @PERM_ADD_PROJECTS
					11: sort: 10, type: 'child', token: 'team_accountant',  nice: 'Account Manager'   	,perm: @PERM_ADD_PROJECTS
					10: sort: 11, type: 'child', token: 'team_admin',  		nice: 'Administrator'   	,perm: @PERM_ADD_PROJECTS
				status:
					0: token: 'pending',  nice: 'Pending'
					1: token: 'valid',    nice: 'Valid'
				bill_system:
					0: token: 'internal',  nice: 'Internal'
					1: token: 'braintree', nice: 'Braintree'
					2: token: 'bank_check',nice: 'Bank Check'
			invites:
				status:
					0: token: 'new',      nice: 'New'
					1: token: 'sent',     nice: 'Sent'
					2: token: 'valid',    nice: 'Valid'
					3: token: 'accepted', nice: 'Accepted'
			bt_plans:
				prefix:
					FREE: join: 3, create: 0, manage: 0
					STR: join: 'Unlimited', create: 0, manage: 0
					STD: join: 'Unlimited', create: 10, manage: 'Unlimited'
					PRO: join: 'Unlimited', create: 'Unlimited', manage: 'Unlimited'
					TEAM: join: 'Unlimited', create: 'Unlimited', manage: 'Unlimited'
					TRIAL: join: 'Unlimited', create: 'Unlimited', manage: 'Unlimited'
			bt_invoice:
				planId:
					Team_Sandbox:
						prefix: 'TEAM', nice: 'Team', desc: 'Team Account'
					Professional_Sandbox:
						prefix: 'PRO', nice: 'Professional', desc: 'Professional Account'
					Standard_Sandbox:
						prefix: 'STD', nice: 'Standard', desc: 'Standard Account'
					Starter_Sandbox:
						prefix: 'STR', nice: 'Starter', desc: 'Starter Account'
					Team:
						prefix: 'TEAM', nice: 'Team', desc: 'Team Account'
					Professional:
						prefix: 'PRO', nice: 'Professional', desc: 'Professional Account'
					Standard:
						prefix: 'STD', nice: 'Standard', desc: 'Standard Account'
					Starter:
						prefix: 'STR', nice: 'Starter', desc: 'Starter Account'						
		#_log f, @choices_cache
		@choices_cache
	@makeIssue: (issueObj,result,more_issue_params) ->
		f= 'E:Rest.makeIssue'
		i_token= 'UNRECOGNIZED' # Populated with final error-token to issueObj.add
		i_params= [] # Will be populated with 2nd param to issueObj.add
		# use: @rest.makeIssue i, result (from REST API result)
		rObj= JSON.parse result
		_log f, issueObj, result, rObj
		if rObj is false
			i_token= 'FALSE'
		else if typeof rObj is 'string'
			if (rMatch= rObj.match /^Error: ([A-Za-z0-9_-]+)/)
				i_params.push rObj
				parts= rMatch[ 1].split '-'
				if parts[ 1] is 'BTMSG'
					i_token= parts[ 0]+ '_'+ parts[ 1]
					i_params.push (((rObj.split '-').slice 2).join '-').replace /\n/g, '<br>'
				else
					i_token= rMatch[1].replace /-/g, '_'
			else
				i_token= 'REST_001_ERROR'; i_params.push rObj
		else if 'code' of rObj and 'message' of rObj
			i_token= rObj.code; i_params.push rObj.message
		else if 'error' of rObj
			i_token= rObj.error
		else
			i_params.push JSON.stringify rObj
		i_params.push param for param in more_issue_params or []
		issueObj.add i_token, i_params

	@get: (resource,caller_info,data) -> @rest resource, caller_info, 'GET', data
	@post:(resource,caller_info,data) -> @rest resource, caller_info, 'POST', data
	@download_file: (url,cb) ->
		f= 'E:Rest.download_file'
		# This requires an updated token, such that no 401 will be expected
		# Use native xhr, since jQuery does not support the blob format
		xhr= new XMLHttpRequest()
		xhr.onloadend= (e) ->
			if @status is 200
			then cb 'success', @response # a blob
			else
				_log f, 'fail', xhr
				cb 'fail', @response
		xhr.onprogress= (e) -> cb 'progress', e.loaded, e.total
		# Add event listeners *before* open
		xhr.open 'GET', url, true
		xhr.responseType= 'blob'
		cb 'start'
		xhr.send()
		return xhr

	@upload_file: (prid,foid,file,action,cb) ->
		# This requires an updated token, such that no 401 will be expected
		formData = new FormData()
		formData.append 'file', file
		resource= "#{prid}/#{foid}" 
		if action then resource+= "/#{action.parent_id}/#{action.type}"
		rest_url= @rest_upload_url
		options=
			url: @rest_upload_url + resource,
			# The proxy option will break the 'token'-as-var option
			#url: 'http://epic.dv-mobile.com/proxy_cors.php?url='+ encodeURIComponent(  @rest_upload_url + resource)
			async: true, dataType: 'json',
			processData: false # Don't let jquery look at formData
			contentType: false # With formData, this prevents losing the boundary
			type: 'POST', data: formData
			progress: (e) -> cb 'progress', e.loaded, e.total
			beforeSend: () -> cb 'start'
		options.headers= Authorization: "#{@token.token_type} #{@token.access_token}"
		#TODO THIS DOES NOT WORK, KILLS SERVER: options.url+= '?auth_token='+ encodeURIComponent "#{@token.access_token}"
		xhr= ($.ajax options).always (data, textStatus, errorThrown) =>
			if textStatus is 'success'
			then cb 'success', data
			else cb 'fail', data
		return xhr
	@rest: (resource, caller_info, method, data_obj, special) -> # Method/data_obj used for POST/PUT/DELETE (or GET w/params?)
		f= "E:Rest.rest(#{caller_info})[#{resource}]"
		#_log2 f
		# Not all resources require auth, so assume we're good until 401'ed
		results= @doData resource, caller_info, method, data_obj, special
		if results is false and @statusCode is 'Unauthorized' # Security issue
			reloading= if @token is false then 'rest1' else 'rest2'
			@doToken()
			if @token is false
				#TODO TRYING LOGOUT INSTEAD OF: throw new Error 'Security.'+ reloading
				#TODO LET DOTOKEN ATTEMPT THIS window.EpicMvc.Epic.logout 'Security.'+ reloading, {}
			else
				# Just one more time
				results= @doData resource, caller_info, method, data_obj, special
		results
	@doToken: (pass) ->
		f= 'E:Rest:@doToken'
		#_log2 f, pass, @token
		if pass # Only a fresh login
			@token= @doData 'Auth', '@doToken-user/pass', 'POST',
				username: @auth_user
				password: pass
				grant_type: 'password'
				client_id: @auth_web_client
		else # Attempt a refresh token
			# TODO Consider avoiding extra refresh when others call this function: return @token if @token isnt false and @refresh_timer isnt false
			if @token is false # Try to load from storage #TODO USE SESSION STORAGE IF USER DOESN'T WANT 'REMEMBER ME'
				@localCache().Restore()
				rtoken= @localCache().Get 'auth_rtoken'
				(@token= refresh_token: rtoken) if rtoken?.length
			if @token
				@token= @doData 'Auth', '@doToken-refresh', 'POST',
					refresh_token: @token.refresh_token
					grant_type: 'refresh_token'
					client_id: @auth_web_client
		if @token
			# Refresh the refresh_token; hold for browser refresh/restart
			if pass
				@localCache().Login auth_rtoken: @token.refresh_token
			else
				@localCache().Put 'auth_rtoken', @token.refresh_token
			if @refresh_timer is false
				@refresh_timer= setTimeout (=> @refresh_timer= false; @doToken()), (@token.expires_in- 10)* 1000
		else if @statusCode is 'Unauthorized' and not pass # Unload any previously stored, not useful rtoken
			@localCache().Logout()
			(clearTimeout @refresh_timer; @refresh_timer= false) if @refresh_timer isnt false
			window.EpicMvc.Epic.logout 'Security.rest1', {}
		#_log f, '@token/statusCode/rtoken', @token, @statusCode, rtoken
		@token # return false if it did not work
	@login: (auth_user,pass) -> # Return false if not successful; persists auth_user (allow missing pass to set default email)
		@logout()
		@auth_user= auth_user
		@localCache().QuickPut 'auth_user', @auth_user
		@doToken pass if pass # Will be false if not a valid login
	@logout: () ->
		@auth_user= @token= false
		@localCache().Logout()
		(clearTimeout @refresh_timer; @refresh_timer= false) if @refresh_timer isnt false
		return
	@doData: (resource, caller_info, method, data_obj,special) ->
		f= "E:Rest.doData(#{caller_info})[#{resource}]"
		data_obj?= {}
		#_log2 f, data_obj
		results= []
		rest_url= @rest_url
		rest_url= @rest_upload_url if special
		options=
			cache: false
			url: rest_url + resource,
			# The proxy option will break the 'token'-as-var option
			#url: 'http://epic.dv-mobile.com/proxy_cors.php?url='+ encodeURIComponent( rest_url + resource),
			async: false, dataType: 'json',
		if special
			options.processData= false
			options.contentType= false # With formData, this prevents losing the boundary
		if typeof method is 'string'
			$.extend options, type: method, data: data_obj
		if @token isnt false
			#options.headers= Authorization: "#{@token.token_type} #{@token.access_token}"
			options.url+= '?auth_token='+ encodeURIComponent "#{@token.access_token}"
		($.ajax options).always (data, textStatus, errorThrown) =>
			if textStatus is 'success'
				#_log f, 'success: data', data
				@statusCode= true # Assume we were good last time
				if 'result' of data
					if 'SUCCESS' of data.result # It's a standard Insert/Update/Delete message
						results= data.result
						return
				else if 'JSON' of data
					results= data.JSON
				else results= data # Not a sql result
				return
			else
				xhr= data
				_log f, statusCode: @statusCode, errorThrown: errorThrown, xhr: xhr
				#alert textStatus+ xhr.statusCode()
				#statusCode= if typeof errorThrown is 'string' then xhr.status else errorThrown.message
				statusCode= if typeof errorThrown is 'string' then errorThrown else errorThrown.name
				_log2 f, statusCode, xhr.responseText
				switch statusCode
					when 'Unauthorized' then results= false
					# 401: xhr.statusText/errorThrown="Unauthorized"; xhr.readyState=4;
					# xhr.responseText= { error: "invalid_client" }
					when 'Forbidden', 'Not Found', 'Bad Request', 'Internal Server Error'
						# TODO NOTE 'Note Found' CAUSED MASSIVE IMMEADIATE RETRYS WHEN API ENDPOINT CHANGED (VERSION ADDED)
						#alert 'Catchable error occured, need to move error into response :xhr.responseText='+ xhr.responseText
						results= xhr.responseText # TODO IF WE CHANGE TO AN ERROR OBJECT ON SERVER, WILL NEED TO JSON.parse
						@statusCode= true # Assume we were good last time
					when 'NS_ERROR_FAILURE', 'Failure', 'NETWORK_ERR' # FF:Failure, Ch:NETWORK_ERR
						# TODO I GET THIS ONCE IN A WHILE DURRING TOKEN REFRESH - SHOULD LET ONE GO W/O CONSREN AND RETRY AFTER A BIT MAYBE?
						# 0: xhr.statusText= "[[Error... long string"; xhr.readyState=0;
						# errorThrown=OBJECT:message:'Failure',name:'NS_ERROR_FAILURE'...;
						alert 'Remote server is unavailable.' if @statusCode isnt 'Failure'
						results= false # TODO FIGURE OUT WHAT SHOULD BE RETURNED
					else
						alert 'Session timed out.  Click to resume.'
						results= false # TODO FIGURE OUT WHAT SHOULD BE RETURNED
				@statusCode= statusCode

		#_log2 f, 'results', results
		return results

window.EpicMvc.Extras.Rest= Rest # Public API
