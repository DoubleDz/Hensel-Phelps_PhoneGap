
class User extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		ss=
			invite_code: false
			tab_home: 'clear'
		super Epic, view_nm, ss
		@rest= window.EpicMvc.Extras.Rest # Static class
		@invite_rec= false
		@xfer_email= false
		@xfer_project= false
		@xfer_details= {}
		@invite_display= {}
		@login_msg= false
	eventLogout: -> true # blow me away
	eventNewRequest: (change) ->
		delete @Table.DynaInfo # Don't cache this, since nothing updates it's values for us
		return if change.track isnt true # Below here we flush the cache as they move out of this track
		delete @c_myself
		@invalidateTables ['Me']

	action: (act,p) ->
		f= "M:User::action(#{act})"
		_log f, p
		r= {}; i= new window.EpicMvc.Issue @Epic, @view_nm, act; m= new window.EpicMvc.Issue @Epic, @view_nm, act
		switch act
			when 'url_invite' # Epic.getExternalUrl wants to know what hashcode to use for SIGNUP_CONFIRM page
				r.url= 'signup_confirm-'+ @invite_code
			when 'url_invite_team' # Epic.getExternalUrl wants to know what hashcode to use for TEM_SIGNUP_CONFIRM page
				r.url= 'team_invite-'+ @invite_code
			when 'check' # Controller wants to know, valid[login]:yes/no, projects[exist]:yes/no
				if (valid= @rest.doToken()) isnt false
					r.valid= 'yes'
					options= @Epic.getViewTable 'Directory/Options'
					if options[0].cache_pending is 'yes'
						r.loading= 'yes'
					else
						projects= @Epic.getViewTable 'Directory/Member'
						r.projects=( if projects.length then 'yes' else 'no')
				else r= valid: 'no'
			when 'login' # Login form (p.AuthEmail, p.AuthPass)
				delete @Table.Me
				oF = @Epic.getFistInstance 'Login'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success = 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.login fv.email, fv.password
				if result isnt false
					projects= @Epic.getViewTable 'Directory/Member'
					@Epic.login() # Let all models know what's up
					rec= @_getMyself()
					@login_msg= true if rec.is_recommendation is true
					@invalidateTables ['LoginMsg']
					r= success: 'SUCCESS', projects:( if projects.length then 'yes' else 'no')
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'clear_login_msg'
				@login_msg= false
				@invalidateTables ['LoginMsg']
			when 'logout'
				@login_msg= false
				@invalidateTables ['LoginMsg']
				@rest.logout()
				@Epic.logout() # Let all models know what's up
			when 'have_email'
				@xfer_email= p.email # Came from e.g. team-add when email is missing
				@xfer_project= p.project # Came from e.g. team-add when email is missing
				r.success= 'SUCCESS'
			when 'forgot_xfer'
				@forgot_xfer_pswd= p.AuthEmail # In case they entered it in the login screen
				r.success= 'SUCCESS'
			when 'send_forgot'
				oF = @Epic.getFistInstance 'UserForgot'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success = 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post 'User_forgot', f, fv
				_log2 f, 'result', result
				if result.SUCCESS is true
					m.add 'EMAIL_SENT', [ fv.email ]
					r= success: 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'choose_user'
				if @userid isnt p.id then @userid= p.id; delete @Table.User
				r.success= 'SUCCESS'
			when 'set_invite_code', 'set_forgot_code' # External url has input code, remember for forms input
				if p.code.length is 5
					endpoint= switch act
						when 'set_invite_code' then 'invite'
						else 'forgot'
					result= @rest.doData "User_#{endpoint}/#{encodeURIComponent p.code}", f, 'GET'
					if result.invite or result.user
						@invite_rec= result.invite ? result.user
						@invite_code= p.code
						r.success= 'SUCCESS'
				if not r.success
					i.add 'INVALID_CODE', [ p.code ]
					r.success= 'FAIL'
			when 'pre_reg_confirm_code' # External url has input code, POST to update db
				if p.code.length is 5
					result= @rest.doData 'PreReg/confirm', f, 'POST', code: p.code
					if result.SUCCESS is true
						m.add 'SUCCESS'
						r.success= 'SUCCESS'
				if not r.success
					i.add 'INVALID_CODE', [ p.code ]
					r.success= 'FAIL'
			when 'confirm_code' # External url has input code, POST to update db
				if p.code.length is 5
					result= @rest.doData "User_confirm/#{encodeURIComponent p.code}", f, 'POST'
					if result.SUCCESS is true
						@rest.login result.user.email # Set default for login
						m.add 'SUCCESS'
						r.success= 'SUCCESS'
				if not r.success
					i.add 'INVALID_CODE', [ p.code ]
					r.success= 'FAIL'
			when 'populate_invite' # Caller has some invite details
				@xfer_details= $.extend {}, p
				@invite_display= name: p.name, email: p.email
				@invalidateTables ['InviteDisplay']
				r.success= 'SUCCESS'
			when 'invite' ,'invite_team' ,'invite_admin' ,'invite_admin_ltd' # UserInvite form (p.AuthEmail, p.Level)
				[endpoint, fist]= switch act
					when 'invite_team' then ['teaminvite', 'UserInviteOther']
					when 'invite_admin' then ['BROKEN', 'UserInviteAdam']
					when 'invite_admin_ltd' then ['BROKEN', 'UserInviteAdamLtd']
					else ['invite', 'UserInviteOther']
				oF= @Epic.getFistInstance fist
				i.call oF.fieldLevelValidate p, fist # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post "User_#{endpoint}", f, fv
				_log2 f, 'result', result
				if result.SUCCESS is true
					m.add 'SENT', [p.email]
					oF.clearValues()
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'invite_team_project' ,'invite_admin_project' # UserInviteProject form (p.AuthEmail, p.Level), p.project_id
				[endpoint, fist]= switch act
					when 'invite_team_project' then ['invite', 'UserInviteProject']
					when 'invite_admin_project' then ['BROKEN', 'UserInviteProjectAdam']
				oF= @Epic.getFistInstance fist
				i.call oF.fieldLevelValidate p, fist # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				fv.project_id= Number p.project_id
				result= @rest.post "User_#{endpoint}", f, fv
				_log2 f, 'result', result
				if result.SUCCESS is true
					m.add 'SENT', [fv.email]
					oF.clearValues()
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'request_invite' # RequestInvite form (pre-registration)
				oF = @Epic.getFistInstance 'RequestInvite'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post 'User_requestinvite', f, fv
				_log2 f, 'result', result
				if result.SUCCESS is true
					m.add 'SENT', [fv.email]
					oF.clearValues()
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'resend_invite' # p.id
				result= @rest.post "User/#{p.id}/reinvite", f, {}
				_log2 f, 'result', result
				if result.SUCCESS is true
					m.add 'RE_SENT'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'register' # UserRegister form (p.AuthEmail, p.AuthPass, ...)
				oF = @Epic.getFistInstance 'UserRegister'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				mExtern= @Epic.getInstance 'External'
				fv.terms_version= mExtern.version.terms_use
				fv.privacy_version= mExtern.version.privacy
				result= @rest.doData "User_register", f, 'POST', fv
				if result.SUCCESS is true
					if result.re_invite
						m.add 'CONFIRM', [fv.email]
						r.success= 'CONFIRM'
					else
						r.success= 'SUCCESS'
						@rest.login fv.email, fv.password
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'forgot_finish' # UserForgotFinish form (p.AuthPass)
				oF = @Epic.getFistInstance 'UserForgotFinish'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.doData 'User_forgotfinish', f, 'POST', fv
				if result.SUCCESS is true
					r.success= 'SUCCESS'
					@rest.login fv.email, fv.password
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'save_profile', 'save_profile_extended', 'save_profile_expose' # Profile_Edit/_Extended form (p.AuthEmail, ...)
				# Also, may have onoffswitch_orig/onoffswtich{project_id:'on'} to per-project contact_flag
				if act isnt 'save_profile_expose'
					flist= if act is 'save_profile' then 'ProfileEdit' else 'ProfileExtended'
					oF= @Epic.getFistInstance flist
					i.call oF.fieldLevelValidate p, flist # Will populate DB side
					if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
					fv = oF.getDbFieldValues()
				else
					fv= {}
					# Add to fv, changed contact_flag settings
					p.onoffswitch?= {}; p.onoffswitch_orig?= {} #TODO FIST SHOULD POPULATE THESE DEFAULTS? UN-CHECKBOXES DONT POST
					fv.contact_flag_on=( prid for prid of p.onoffswitch when not (prid of p.onoffswitch_orig))
					fv.contact_flag_off=( prid for prid of p.onoffswitch_orig when not (prid of p.onoffswitch))
				_log2 f, 'fv', fv
				result= @rest.post 'User/me/update', f, fv
				if result.SUCCESS is true
					if result.email_sent is true
						m.add 'SENT', [fv.email]
					delete @c_myself
					delete @Table.Me
					m.add 'SUCCESS'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'save_password' # ChangePass form (p.AuthEmail, ...)
				oF = @Epic.getFistInstance 'ChangePass'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post 'User/me/updatepass', f, fv
				if result.SUCCESS is true
					oF.clearValues()
					m.add 'SUCCESS'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'tab_home_clear', 'tab_home_sign_in', 'tab_home_request_invite'
				# User/Options/tab_home_request_invite
				tab= act.slice 'tab_home_'.length
				if @tab_home isnt tab
					@tab_home= tab
					@invalidateTables ['Options']
				r.success= 'SUCCESS'
			else return super act, p
		#_log2 f, 'return', r, i, m
		[r, i, m]
	loadTable: (tbl_nm) ->
		f= "M:User::loadTable(#{tbl_nm})"
		#_log2 f
		switch tbl_nm
			when 'Me'
				rec= @_getMyself()
				me= $.extend { expires_days: '', Stats: [], Plan: [], Payment: [], is_recommendation: '', recommended_price: '', has_spships: ''}, rec.users[0]
				level_map= @rest.choices().users.level[me.level] ? type: 'none', perm: 0, nice: 'Pending'
				me.can_add_projects= if level_map.perm& @rest.PERM_ADD_PROJECTS then 'yes' else ''
				me.is_team_admin= if level_map.token is 'team_admin' then 'yes' else ''
				me.is_team_accountant= if level_map.token is 'team_accountant' then 'yes' else ''
				me.is_team_owner= if level_map.type is 'parent' then 'yes' else ''
				me.level_nice= level_map.nice
				me.bytes_quota=( Number me.mbytes_quota)* 1024* 1024
				if rec.is_recommendation is true
					me.is_recommendation= 'yes'
					me.recommended_price= rec.plan.estimated_price
					now= new Date()
					me.expires_days= Math.round ((Date.parse rec.payment.expires)- now)/ 86400000+ 1
					me.expires_days= 0 if me.expires_days < 0
					me.Plan= [rec.plan]
					me.Stats= [rec.stats]
					me.has_spships= rec.stats.sponsorships # But only if is_recommenation, fyi
				else if 'payment' of rec
					me.Payment= [rec.payment]
					now= new Date()
					me.expires_days= Math.round ((Date.parse rec.payment.expires)- now)/ 86400000+ 1
					me.expires_days= 0 if me.expires_days < 0
				@Table[tbl_nm]= [me]
			when 'Options'
				#_log2 f, 'Options before', @Table[tbl_nm]
				row= port: (window.EpicMvc.Extras.options.RestEndpoint.split ':')[2]
				row.tab_home_clear= if @tab_home is 'clear' then 'yes' else ''
				row.tab_home_sign_in= if @tab_home is 'sign_in' then 'yes' else ''
				row.tab_home_request_invite= if @tab_home is 'request_invite' then 'yes' else ''
				@Table[tbl_nm]= [ row ]
				#_log2 f, 'Options after', @Table[tbl_nm]
			when 'InviteDisplay' # Few fields to display, that are not editable
				results= [ @invite_display ]
				@Table[tbl_nm]= results
			when 'Invite'
				results= [ mailto: '' ] # Populated only directly after (and by) action:invite
				@Table[tbl_nm]= results
			when 'LoginMsg'
				result= []
				row= {}
				if @login_msg isnt false
					rec= @_getMyself()
					$.extend row, rec.stats
					row.plan_price= rec.plan.base_price
					row.plan_name= rec.plan.plan_name
					now= new Date()
					row.expires_days= Math.round ((Date.parse rec.payment.expires)- now)/ 86400000+ 1
					row.expires_days= 0 if row.expires_days < 0
					row.is_expired= ''
					result.push row
				@Table[tbl_nm]= result
			when 'DynaInfo'
				rest_results= @rest.get 'User/me/uploadedmbytes', f
				mbytes= Number rest_results.mbytes
				results= [ mbytes_used: mbytes, bytes_used: mbytes* 1024* 1024 ]
				@Table[tbl_nm]= results
			else return super tbl_nm
		#_log2 f, 'after', @Table[tbl_nm]
		return
	fistLoadData: (oFist) ->
		f= "M:User.fistLoadData(#{oFist.getFistNm()})"
		switch oFist.getFistNm()
			when 'Login' # Dont' populate at this time - could preserver email, so they dont' have to keep typing it though
				oFist.setFromDbValues email: (window.EpicMvc.Extras.localCache.QuickGet 'auth_user') ? ''
			when 'UserForgot'
				if @forgot_xfer_pswd
					oFist.setFromDbValues email: @forgot_xfer_pswd
					delete @forgot_xfer_pswd
			when 'UserInviteOther', 'UserInviteTeam', 'UserInviteAdam', 'UserInviteAdamLtd'
				me= @_getMyself().users[0]
				if @xfer_email isnt false
					email= @xfer_email
					project= @xfer_project
					@xfer_email= false # Forget it now
					@xfer_project= false # Forget it now
				else email= ''
				oFist.setFromDbValues
					msg: "#{me.first_name} #{me.last_name} wants to invite you to join iProjectMobile."
					email: email, project_id: project
				oFist.setFromDbValues @xfer_details
				@xfer_details= {}
			when 'UserInviteProject', 'UserInviteProjectAdam'
				me= @_getMyself().users[0]
				if @xfer_email isnt false
					email= @xfer_email
					project= @xfer_project
					@xfer_email= false # Forget it now
					@xfer_project= false # Forget it now
				else email= ''
				oFist.setFromDbValues
					email: email, project_id: project
				oFist.setFromDbValues @xfer_details
				@xfer_details= {}
			when 'ChangePass'
				null # Leave empty
			when 'UserRegister', 'UserForgotFinish', 'RequestInvite'
				oFist.setFromDbValues @invite_rec if @invite_rec isnt false  # have context?
			when 'ProfileEdit', 'ProfileExtended'
				oFist.setFromDbValues @_getMyself().users[0]
			else return super oFist
	fistGetFieldChoices: (oFist, field) ->
		f= 'M:User.fistGetFieldChoices:'+ oFist.getFistNm()+ ':'+ field
		#_log2 f, oFist
		switch field
			when 'State', 'StateReq'
				options= []; values= []
				fdef= oFist.getFieldAttributes field
				if 'choice' of fdef
					options.push fdef.choice; values.push ''
				(options.push o; values.push v) for v,o of window.state_codes
				options: options, values: values
			when 'LevelTeam'
				choices=( [rec.sort, rec.nice, rec.token] for nm,rec of @rest.choices().users.level when rec.type is 'child')
				choices.sort (a,b) -> a[0]- b[0]
				options:( val[1] for val in choices)
				values: ( val[2] for val in choices)
			when 'Level'
				choices=( [rec.sort, rec.nice, rec.token] for nm,rec of @rest.choices().users.level when rec.type isnt 'child')
				choices.sort (a,b) -> a[0]- b[0]
				options:( val[1] for val in choices)
				values: ( val[2] for val in choices)
			else return super oFist, field
	_getMyself: (force) ->
		f= 'M:User._getMyself'
		return @c_myself if @c_myself and force isnt true
		@c_myself= @rest.get 'User/me', f
		@login_msg= false if @c_myself.is_recommendation isnt true # Turn off login_msg if/when situation changes (purchase plan, etc.)
		if 'plan' of @c_myself
			$.extend @c_myself.plan, @rest.choices().bt_plans.prefix[ @c_myself.plan.prefix]
		@c_myself

	UpdateUserAsync: (cmd,rec) =>
		f= 'M:User.UpdateUserAsync:'+cmd
		@_getMyself()
		_log2 f, 'c_myself/rec', @c_myself, rec
		$.extend @c_myself.users[0], rec # Expect 'merge' for now
		@invalidateTables ['Me']
		return

window.EpicMvc.Model.User= User # Public API
