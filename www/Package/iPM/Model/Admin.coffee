class Admin extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		ss=
			state_code: 'CO'
			user_edit: false
		super Epic, view_nm, ss
		@rest= window.EpicMvc.Extras.Rest # Static class
		@sponsor_add_issue= false # Set to email of unknown user, for option to invite
		@sponsor_add_open= false # Is hidden add-by-email showing?
		@xfer_email= false

	eventNewRequest: (change) ->
		@Table= {}
		delete @c_projects
		return if change.track isnt true
		# These will be updated by our model actions until we leave this 'track'
		# If needed, could add a refresh action
		delete @c_prereg_summary
		delete @c_prereg_projects
		delete @c_users
		delete @c_pstats
		delete @braintree_confirm
		delete @c_payments
		delete @c_bank_check
	eventLogout: -> return true
	action: (act,p) ->
		f= "M:Admin.action(#{act})"
		_log f, p
		r= {}
		i= new window.EpicMvc.Issue @Epic, @view_nm, act
		m= new window.EpicMvc.Issue @Epic, @view_nm, act
		switch act
			when 'choose_user_edit' # p.id
				id= Number p.id
				if @user_edit isnt id
					@user_edit= id
					@invalidateTables ['UserEdit']
				r.success= 'SUCCESS'
			when 'prereg_state' # p.state_code
				stcd= p.state_code # Could be 'null'
				if @state_code isnt stcd
					@state_code= stcd
					@invalidateTables ['PreReg']
				r.success= 'SUCCESS'
			when 'bankcheck_clear' # AdminUserEditBankcheck
				oF = @Epic.getFistInstance 'AdminUserEditBankcheck'
				oF.clearValues()
				delete @bankcheck_confirm
			when 'onchange_bankcheck'
				oF = @Epic.getFistInstance 'AdminUserEditBankcheck'
				oF.fb_HTML[ p.field]= p.value
				@invalidateTables ['BcCalc']
			when 'user_save_bankcheck_temp' # AdminUserEditBankcheck
				oF = @Epic.getFistInstance 'AdminUserEditBankcheck'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				@bankcheck_confirm= fv
				r.success= 'SUCCESS'
			when 'user_save_bankcheck' # AdminUserEditBankcheck
				oF = @Epic.getFistInstance 'AdminUserEditBankcheck'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				fv.bill_system= 'bank_check' # Hijack user's billing entity
				fv.system_total= @c_last_system_total
				result= @rest.post "User/#{@user_edit}/purchase", f, fv
				if result.SUCCESS is true
					delete @bankcheck_confirm
					# TODO MAYBE SERVER CAN SEND US THE updated_payment RECORD TOO; FOR NOW DELETE AND RE_READ ALL PAYMENTS
					delete @c_payments
					@c_users[@user_edit][nm]= val for nm,val of result.updated_user
					@user_edit= false if p.clear
					@invalidateTables true
					m.add 'SUCCESS'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'user_save' # AdminUserEdit
				oF = @Epic.getFistInstance 'AdminUserEdit'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				# Process 'expires' as #days or date
				if fv.expires.length
					fail= false
					days= Number fv.expires
					if isNaN days
						try dt= new Date fv.expires catch e
							fail= e.message
					else
						dt= new Date()
						dt.setDate dt.getDate()+ days
					fail= 'Invalid' if isNaN dt.getMonth()
					if fail isnt false
						i.add 'BAD_DATE', [fail]
						r.success= 'FAIL'
						return [r,i,m]
					fv.expires= "#{dt.getMonth()+1}/#{dt.getDate()}/#{dt.getFullYear()}"
					# Did it change?
					me= @c_users[@user_edit]
					pay= @_getPayments()[me.bill_system][me.id]
					if pay
						dt= new Date pay.expires
						expires_date="#{dt.getMonth()+1}/#{dt.getDate()}/#{dt.getFullYear()}"
						fv.expires= '' if fv.expires is expires_date
				result= @rest.post "User/#{@user_edit}/adminupdate", f, fv
				if result.SUCCESS is true
					@invalidateTables true
					@c_users[@user_edit][nm]= fv[nm] for nm of fv when nm of @c_users[@user_edit]
					@user_edit= false if p.clear
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'user_save_level' # AdminUserEditLevel
				# p.LevelEffect: Types of followup actions, based on subscription-level setting
				# (a) no change to existing membership
				# (b) update 'class' (effective non-viewable)
				# (c) update 'invited_as' (effects public I/F with others)
				# (d) also disable projects they were owners of
				oF = @Epic.getFistInstance 'AdminUserEditLevel'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				level_num= fv.level
				fv.level= @rest.choices().users.level[level_num]?.token ? 'unknown'
				result= @rest.post "User/#{@user_edit}/adminupdatelevel", f, fv
				if result.SUCCESS is true
					fv.level= level_num
					@c_users[@user_edit][nm]= fv[nm] for nm of fv when nm of @c_users[@user_edit]
					@user_edit= false if p.clear
					@invalidateTables true
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'user_disable' # use @user_edit
				result= @rest.post "User/#{@user_edit}/admindisable", f
				if result.SUCCESS is true
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'sponsor_del' # p.id
				id= Number p.id
				result= @rest.post "Sponsor/#{id}/remove", f, mask_usid: @user_edit
				if result.SUCCESS is true
					@invalidateTables ['Sponsor']
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'add_sponsor_open', 'add_sponsor_close'
				@sponsor_add_open= act is 'add_sponsor_open'
				@sponsor_add_issue= false
				@invalidateTables ['SponsorAdd']
			when 'sponsor_level' # p.id, p.as 'team_XXX'
				new_level= p.as
				result= @rest.post "Sponsor/#{p.id}/updatelevel" , f, level: new_level, mask_usid: @user_edit
				if result.SUCCESS is true
					@invalidateTables ['Sponsor']
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'sponsor_add' # fist: SponsorAddEmail
				oF = @Epic.getFistInstance 'SponsorAddEmail'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				fv.mask_usid= @user_edit
				result= @rest.post "Sponsor/email/add" , f, fv
				if result.SUCCESS is true
					@invalidateTables ['Sponsor']
					r.success= 'SUCCESS'
				else if result.match /^"Error: REST_404_USERS/
					@sponsor_add_issue= fv.email
					@invalidateTables ['SponsorAdd']
					r.success= 'NO_SUCH_USER'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'invite_for_team' # UserInviteForTeam
				fist= 'UserInviteForTeam'
				oF= @Epic.getFistInstance fist
				i.call oF.fieldLevelValidate p, fist # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				fv.usid= @user_edit # The 'Pro' user
				result= @rest.post 'User_invite', f, fv
				_log2 f, 'result', result
				if result.SUCCESS is true
					m.add 'SENT', [p.email]
					oF.clearValues()
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'have_email'
				@xfer_email= p.email # Came from e.g. sponsor-add when email is missing
				r.success= 'SUCCESS'
			when 'email_test' # AdminEmailTest
				oF = @Epic.getFistInstance 'AdminEmailTest'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.get "Admin_testemail", f, fv
				if result.SUCCESS is true
					m.add 'SUCCESS'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			else return super act, p
		[r, i, m]
	loadTable: (tbl_nm) ->
		f= "M:Admin.loadTable(#{tbl_nm})"
		#_log2 f
		switch tbl_nm
			when 'Bankcheck'
				@_getBankCheckPlans()
				table= []
				for nm,row of @c_bank_check
					new_row= $.extend {}, row
					table.push new_row
				@Table[tbl_nm]= table
			when 'Options'
				row= prereg_state: @state_code, prereg_state_nice: window.state_codes[@state_code] ? 'empty'
				@Table[tbl_nm]= [ row ]
			when 'UserEdit'
				row= @_getUsers()[@user_edit]
				results= []
				new_row= $.extend {}, row
				new_row.bytes_quota= row.mbytes_quota* 1024* 1024
				new_row.level_nice= @rest.choices().users.level[row.level]?.nice ? 'unknown'
				new_row.status_nice= @rest.choices().users.status[row.status]?.nice ? 'unknown'
				new_row.state_nice= window.state_codes[row.state] ? 'No-state'
				rest_results= @rest.get "User/#{@user_edit}/uploadedmbytes", f
				mbytes= Number rest_results.mbytes
				new_row.mbytes_used= mbytes
				new_row.bytes_used= mbytes* 1024* 1024
				results.push new_row
				@Table[tbl_nm]= results
			when 'User'
				@_getPStats() # For now, do this always; later, could put into own table to speed things up
				users= @_getUsers()
				payments= @_getPayments() # [1/2] BankCheck/Braintree payment info, indexed by user_id
				results= []
				for id,row of users
					new_row= $.extend {expires_days: '', is_pending: '', is_BT: '', BT: [], is_BC: '', BC: []}, row
					new_row.bytes_quota= row.mbytes_quota* 1024* 1024
					new_row.level_nice= @rest.choices().users.level[row.level]?.nice ? 'unknown'
					new_row.level_token= @rest.choices().users.level[row.level]?.token ? 'unknown'
					new_row.is_pending= 'yes' if row.status isnt 1
					new_row.status_nice= @rest.choices().users.status[row.status]?.nice ? 'unknown'
					new_row.state_nice= window.state_codes[row.state] ? 'No-state'
					new_row.state= '' unless row.state?
					new_row.city= '' unless row.city?
					new_row.bill_system_token= @rest.choices().users.bill_system[row.bill_system]?.token ? 'unknown'
					new_row.bill_system_nice= @rest.choices().users.bill_system[row.bill_system]?.nice ? 'Unknown'
					switch new_row.bill_system
						when 1 then obj= new_row.BT; new_row.is_BT= 'yes'
						when 2 then obj= new_row.BC; new_row.is_BC= 'yes'
					if row.id of payments[row.bill_system]
						obj.push $.extend {}, payments[row.bill_system][row.id]
						dt= new Date obj[0].expires
						obj[0].expires_date="#{dt.getMonth()+1}/#{dt.getDate()}/#{dt.getFullYear()}"
						obj[0].expires_days= Math.round (( Date.parse obj[0].expires)- new Date())/ 86000000
						obj[0].expires_days= 0 if obj[0].expires_days< 0
						new_row.expires_days= obj[0].expires_days
					if row.created isnt '0000-00-00 00:00:00' 
						time = new Date row.created
						y = time.getFullYear()
						mo = ("0"+(time.getMonth()+1)).slice(-2)
						d = ("0"+time.getDate()).slice(-2)
						h = ("0"+time.getHours()).slice(-2)
						mi = ("0"+time.getMinutes()).slice(-2)
						new_row.created_nice= y + '-' + mo + '-' + d + ' ' + h + ':' + mi
					else
						new_row.created_nice= '---'
					results.push new_row
				@Table[tbl_nm]= results
			when 'PreRegSummary'
				data= @_getPreRegSummary()
				results= []
				for row in data.summary #TODO STATUS when row.status is 2
					new_row= $.extend {}, row
					new_row.status_nice= @rest.choices().invites.status[row.status]?.nice ? 'unknown'
					new_row.state_nice= window.state_codes[row.state] ? 'No-state'
					results.push new_row
				@Table[tbl_nm]= results
			when 'PreReg'
				data= @rest.get "PreReg/State/#{@state_code}", f
				results= []
				for row in data.invites when row.status is 2
					new_row= $.extend {}, row
					results.push new_row
				@Table[tbl_nm]= results
			when 'Owner' # All projects and their owners
				curr_projects= @_getProjects()
				data= @rest.get 'Project', f
				# Index the owners, then build projects w/owner data where available
				owners= {}
				owners[rec.project_id]= rec for rec in data.owners
				results= []
				for row in data.projects when row.type is 1
					owner= owners[row.id] ? first_name: '', last_name: '', email: 'NONE'
					new_row= $.extend {}, row, owner, is_watching: ''
					new_row.is_watching= 'yes' if row.id of curr_projects
					results.push new_row
				results.sort (a,b) ->
					if a.name.toLowerCase() is b.name.toLowerCase() then 0
					else if a.name.toLowerCase()> b.name.toLowerCase() then 1
					else -1
				@Table[tbl_nm]= results
			when 'Sponsor'
				rest_results= @rest.get "Sponsor", f, mask_usid: @user_edit
				results= []
				for row in (rest_results.sponsors ? [])
					new_row= $.extend {}, row
					new_row.level_nice= @rest.choices().users.level[row.level]?.nice ? '?'
					new_row.level_token= @rest.choices().users.level[row.level]?.token ? '?'
					results.push new_row
				@Table[tbl_nm]= results
			when 'SponsorAdd'
				table= []
				table.push
					issue: if @sponsor_add_issue is false then '' else 'yes'
					issue_email: @sponsor_add_issue
					open: if @sponsor_add_open is true then 'yes' else ''
				@Table[tbl_nm]= table
			when 'BcCalc'
				@Table[tbl_nm]= [is_valid: ''] # Default if not able to build calculated values
				oF= @Epic.getFistInstance 'AdminUserEditBankcheck'
				oF.Fb_Html2Db 'AdminUserEditBankcheck' # Popluate DB side
				vals= oF.getDbFieldValues()
				nums= {} # numeric values
				(nums[nm]= (Number val) ? 0) for nm,val of vals
				plan= false # Default, not found
				for rec in (@Epic.getViewTable 'Billing/Bankcheck')
					if rec.id is Number nums.plan_id
						plan= rec
						break
				return if plan is false
				# DB Plan: base_price base_spships base_gigs
				# Form vals: extra_spships extra_gblocks months total_check
				# Calcualted: total_spships total_gblock total_month total_total total_discount
				row= $.extend {
					total_spships:0, total_gblock:0
					total_month:0, total_check:0
					total_total:0, total_discount:0, discount_pct: 0
					}, plan, nums
					
				# Calc per-unit montly price on #sponsors and #gig-units
				row.total_spships= row.spship_price* row.extra_spships
				row.total_gblock= row.gblock_price* row.extra_gblocks
				# Calc mothly total and final cost
				row.total_month= row.base_price+ row.total_spships+ row.total_gblock
				if row.months
					row.total_total= row.total_month* row.months
				
				row.total_check= row.check_total # Our name is not like the DB's name
				if row.check_total
					row.total_discount= row.total_total- row.total_check
					row.discount_pct= (row.total_discount / row.total_total* 100).toFixed 1
				row.is_valid= 'yes'
				@c_last_system_total= row.total_total
				@Table[tbl_nm]= [row]
			else super tbl_nm
		#_log2 f, 'after', @Table[tbl_nm]
		return
	_getPreRegSummary: () ->
		f= "M:Admin._getPreRegSummary"
		return @c_prereg_summary if @c_prereg_summary
		@c_prereg_summary= @rest.get 'PreReg/State', f
	_getProjects: () ->
		f= "M:Admin._getProjects"
		return @c_projects if @c_projects
		@c_projects=( @Epic.getInstance 'Directory').getActiveProjectList()
	_getUsers: () ->
		f= "M:Admin._getUsers"
		return @c_users if @c_users # Note, hash by user-id
		results= @rest.get 'User', f
		return {} if not ('users' of results)
		@c_users= {}
		@c_users[rec.id]= rec for rec in results.users
		@c_users
	_getPayments: () ->
		f= "M:Admin._getPaments"
		return @c_payments if @c_payments
		results= @rest.get 'User_payment', f
		@c_payments= [ {}, {}, {}] # System, Braintree=1, Bankcheck=2
		(@c_payments[1][rec.user_id]= rec) for rec in (results.braintree ? [])
		(@c_payments[2][rec.user_id]= rec) for rec in (results.bank_check ? [])
		@c_payments
	_getPStats: () -> # Merge this into @c_users
		f= "M:Admin._getPStats"
		return @c_pstats if @c_pstats
		@_getUsers()
		results= @rest.get 'User_pstats', f
		# Results has user_owned_projects{user_id,id} (must count them), project_size (use later), user_memberships{user_id,count,invited_as,class}
		# Put into @c_users: cnt_projects_owned, cnt_watch, cnt_watch_restricted, ...
		map=
			'30:30': 'cnt_watch',   '30:1': 'cnt_watch_demoted',   '30:0': 'cnt_watch_restricted'
			'20:20': 'cnt_owner',   '20:1': 'cnt_owner_demoted',   '20:0': 'cnt_owner_restricted'
			'20:10': 'cnt_owner_demoted' # Special case of 'demoted' from owner to manager (team members might get this?)
			'10:10': 'cnt_manager', '10:1': 'cnt_manager_demoted', '10:0': 'cnt_manager_restricted'
			'0:2'  : 'cnt_member_plus',  '0:1' : 'cnt_member',     '0:0' : 'cnt_member_restricted'
			'what?': 'what?'
		for user_id, row of @c_users # Defaults
			$.extend row, cnt_projects_owned: '', sub_parent: '', sub_cnt_children: '', sub_children: '', inv_who: '', inv_who_email: '', inv_cnt: 0
			row[ val]= '' for nm, val of map
		# Sum up some of the row data from the server
		cnt_projects= {}
		for row in results.user_owned_projects
			cnt_projects[ row.user_id]?= 0
			cnt_projects[ row.user_id]++
		sub_cnt_children= {}
		sub_cnt_parents= {}
		for row in results.sponsorships
			sub_cnt_children[row.parent_user_id]?= []
			sub_cnt_children[row.parent_user_id].push row.child_user_id
			sub_cnt_parents[row.child_user_id]?= []
			sub_cnt_parents[row.child_user_id].push row.parent_user_id
		@c_users[ user_id].cnt_projects_owned= count for user_id, count of cnt_projects
		@c_users[ row.user_id][ map[ row.invited_as+ ':'+ row.class] ? 'what?']= row.count for row in results.user_memberships
		for child,row of sub_cnt_parents
			@c_users[ child].sub_parent= row.join ',' # If more than one parent, it'll show the list, fyi
		for parent,row of sub_cnt_children
			@c_users[ parent].sub_cnt_children= row.length
			@c_users[ parent].sub_children= row.join '~'
		for row in results.invites
			@c_users[row.usid].inv_who= row.susid
			@c_users[row.usid].inv_who_email= @c_users[row.susid].email
			@c_users[row.susid].inv_cnt++
		@c_pstats= results
	_getBankCheckPlans: () ->
		f= "M:Admin._getBankCheckPlans"
		return @c_bank_check if @c_bank_check
		@c_bank_check= {}
		rest_results= @rest.get 'User/me/bill_plans', f
		if 'bank_check' of rest_results
			(@c_bank_check[rec.id]= rec) for rec in rest_results.bank_check
		
	fistLoadData: (oFist) ->
		f= "M:Admin.fistLoadData(#{oFist.getFistNm()})"
		switch oFist.getFistNm()
			when  'AdminUserEdit', 'AdminUserEditLevel'
				me= @_getUsers()[@user_edit]
				oFist.setFromDbValues @_getUsers()[@user_edit]
				pay= @_getPayments()[me.bill_system][me.id]
				if pay
					dt= new Date pay.expires
					expires_date="#{dt.getMonth()+1}/#{dt.getDate()}/#{dt.getFullYear()}"
					oFist.setFromDbValues expires: expires_date
			when  'AdminUserEditBankcheck'
				if @bankcheck_confirm
					oFist.setFromDbValues @bankcheck_confirm
				else if @c_users[@user_edit].bill_system is 2
					oFist.setFromDbValues @c_payments[2][@user_edit]
				else
					oFist.setFromDbValues plan_id: 1, extra_spships: 0, extra_gblocks: 0, months: 1, check_total: 0
			when 'UserInviteForTeam'
				pro= @_getUsers()[@user_edit]
				if @xfer_email isnt false
					email= @xfer_email
					@xfer_email= false # Forget it now
				else email= ''
				oFist.setFromDbValues
					msg: "#{pro.first_name} #{pro.last_name} wants to invite you to join iProjectMobile."
					email: email
			when 'AdminEmailTest'
				null # Leave blank
			else return super oFist
	fistGetFieldChoices: (oFist, field) ->
		f= 'M:Folder.fistGetFieldChoices:'+ oFist.getFistNm()+ ':'+ field
		_log2 f, oFist
		switch field
			when 'Level'
				results=( [val.sort, val.nice, nm] for nm,val of @rest.choices().users.level)
				results.sort (a,b) -> a[0]- b[0]
				options:( rec[1] for rec in results), values: ( rec[2] for rec in results)
			when 'PreRegState'
				options= []; values= []
				for rec in @_getPreRegSummary() when rec.status is 2
					options.push window.state_codes[rec.state]+ " (#{rec.count})"; values.push rec.state
			when 'BcPlanChoice'
				options= []; values= []
				fdef= oFist.getFieldAttributes field
				if 'choice' of fdef
					options.push fdef.choice; values.push ''
				for rec in (@Epic.getViewTable 'Billing/Bankcheck')
					options.push rec.plan_name; values.push String rec.id
				_log2 f, options: options, values: values
				options: options, values: values
			else return super oFist, field

window.EpicMvc.Model.Admin= Admin # Public API
