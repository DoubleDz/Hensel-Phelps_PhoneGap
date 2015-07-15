
class Sponsor extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		ss=
		super Epic, view_nm, ss
		@rest= window.EpicMvc.Extras.Rest # Static class
		@sponsor_add_issue= false # Set to email of unknown user, for option to invite
		@sponsor_add_open= false # Is hidden add-by-email showing?
		@sponsor_add_rows= []
		@c_sponsor_data= false
	eventLogout: -> true # blow me away
	eventNewRequest: () ->
		delete @Table.Sponsor # Don't cache this, since nothing updates it's values for us
		delete @Table.Owner # Don't cache this, since nothing updates it's values for us
		delete @c_projects
		@c_sponsor_data= false
	action: (act,p) ->
		f= "M:Sponsor::action(#{act})"
		_log f, p
		r= {}
		i= new window.EpicMvc.Issue @Epic, @view_nm, act
		m= new window.EpicMvc.Issue @Epic, @view_nm, act
		switch act
			when 'clear_new_sponsor_rows'
				oF= @Epic.getFistInstance 'AddNewTeamUser'
				oF.clearValues()
				@sponsor_add_rows = []
				@invalidateTables ['SponsorAddRows']
			when 'invite_new_sponsor_row' # p.id
				map= window.EpicMvc['issues$'+ @Epic.appConf().getGroupNm()]
				oF= @Epic.getFistInstance 'AddNewTeamUser'
				row= @sponsor_add_rows[p.id]
				delete row.error
				i_row= new window.EpicMvc.Issue @Epic, @view_nm, act
				oF.clearValues()
				i_row.call oF.fieldLevelValidate row # Will populate DB side
				save= issues: oF.fb_issues, html: oF.fb_HTML
				if i_row.count() > 0
					r.success= 'FAIL'
				else
					fv = oF.getDbFieldValues()
					result= @rest.post "Sponsor/email/add" , f, fv
					if result.SUCCESS is true
						row.success = true
					else
						@rest.makeIssue i_row, result
						row.error= i_row.asTable(map)[0].issue
				oF.clearValues()
				if row.success
					@sponsor_add_rows.splice (Number p.id), 1
					m.add 'INVITE_SPONSOR_ROW_SUCCESS',[row.TeamEmail]
				else
					(oF.fb_issues[key+ '__'+ p.id]= save.issues[key]) for key of save.issues # Populate row-based issue fields
					(row[key]= save.html[key]) for key of save.html # Retrieve cleaned-up values
				@invalidateTables ['SponsorAddRows']
			when 'update_new_sponsor_field'
				@sponsor_add_rows[p.id][p.name]= $(p.input_obj).val()
				oFist= @Epic.getFistInstance 'AddNewTeamUser'
				oFist.fb_HTML[p.name+'__'+p.id]= $(p.input_obj).val()
			when 'send_new_sponsor_rows'
				form_issues= []
				bad_rows= []
				map= window.EpicMvc['issues$'+ @Epic.appConf().getGroupNm()]
				oF= @Epic.getFistInstance 'AddNewTeamUser'
				for row,ix in @sponsor_add_rows
					i_row= new window.EpicMvc.Issue @Epic, @view_nm, act
					row.error= ''
					row.error_token= ''
					row.is_invitable= false
					oF.clearValues()
					i_row.call oF.fieldLevelValidate row # Will populate DB side
					if i_row.count() > 0
						r.success= 'FAIL'
					else
						fv = oF.getDbFieldValues()
						result= @rest.post "User_teaminvite" , f, fv
						if result.SUCCESS is true
							row.success = true
						else
							me=( @Epic.getInstance 'User')._getMyself()
							@rest.makeIssue i_row, result, [me.users[0].sponsorships]
							row.error_token= i_row.asTable(map)[0].token
							row.error= i_row.asTable(map)[0].issue
							row.is_invitable= true if result is '"Error: REST_403_USER_EMAIL_EXISTS"'
					if not row.success
						form_issues.push [bad_rows.length, oF.fb_issues, oF.fb_HTML]
						bad_rows.push row
				count= @sponsor_add_rows.length- bad_rows.length
				oF.clearValues() # Will clear even errors
				if bad_rows.length
					if form_issues.length
						i.add 'FORM_ERRORS'
						for line in form_issues
							[row, i_map, h_map]= line
							(oF.fb_issues[key+'__'+row]= i_map[key]) for key of i_map
							(bad_rows[row][key]= h_map[key]) for key of h_map
				else r.success= 'SUCCESS'
				if count > 0
					m.add 'ADD_SPONSOR_ROW_SUCCESS',[count]
				@sponsor_add_rows = bad_rows
				@invalidateTables ['SponsorAddRows']
			when 'sponsor_del' # p.id
				id= Number p.id
				result= @rest.post 'Sponsor/'+ id+ '/remove', f
				if result.SUCCESS is true
					if result.projects_without_owners.length
						m.add 'OWNERS_REMOVED'
						for project in result.projects_without_owners
							m.add 'NO_OWNER_FOR_PROJECT', [project.name]
					@invalidateTables ['Sponsor']
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'add_sponsor_open', 'add_sponsor_close'
				@sponsor_add_open= act is 'add_sponsor_open'
				@sponsor_add_issue= false
				@invalidateTables ['SponsorAdd']
			when 'add_new_sponsor_row'
				@sponsor_add_rows.push {}
				@invalidateTables ['SponsorAddRows']
			when 'remove_team_user_row' # p.id
				@sponsor_add_rows.splice (Number p.id), 1
				oFist= @Epic.getFistInstance 'AddNewTeamUser'
				oFist.clearValues()
				@invalidateTables ['SponsorAddRows']
			when 'sponsor_level' # p.id, p.as 'standard'/'limited'
				result= @rest.post "Sponsor/#{p.id}/updatelevel" , f, level: p.as
				if result.SUCCESS is true
					if result.projects_without_owners.length
						m.add 'OWNERS_REMOVED'
						for project in result.projects_without_owners
							m.add 'NO_OWNER_FOR_PROJECT', [project.name]
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
			when 'choose_team_user' # (p.id)
				member= if p.id then Number p.id else false
				if @member_edit isnt member
					@member_edit= member
					@invalidateTables ['Sponsor']
				r.success= 'SUCCESS'
			when 'save_team_user' # fist: ModifyTeamUser
				oF = @Epic.getFistInstance 'ModifyTeamUser'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post "User/#{@member_edit}/reinvite" , f, fv
				if result.SUCCESS is true
					@invalidateTables ['Sponsor']
					m.add 'RE_SENT'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			else return super act, p
		#_log2 f, 'return', r, i, m
		[r, i, m]
	loadTable: (tbl_nm) ->
		f= "M:Sponsor::loadTable(#{tbl_nm})"
		#_log2 f
		switch tbl_nm
			when 'Sponsor'
				rest_results= @_getSponsorData()
				results= []
				for row in (rest_results.sponsors ? [])
					new_row= $.extend {}, row, is_edit:''
					new_row.level_nice= @rest.choices().users.level[row.level]?.nice ? '?'
					new_row.level_token= @rest.choices().users.level[row.level]?.token ? '?'
					new_row.is_edit= 'yes' if new_row.id is @member_edit
					results.push new_row
				@Table[tbl_nm]= results
			when 'SponsorAdd'
				table= []
				table.push
					issue: if @sponsor_add_issue is false then '' else 'yes'
					issue_email: @sponsor_add_issue
					open: if @sponsor_add_open is true then 'yes' else ''
				@Table[tbl_nm]= table
			when 'SponsorAddRows'
				table= []
				id= 0
				for row in @sponsor_add_rows
					new_row= $.extend {error:'', is_invitable:''}, row, id:id++
					new_row.level_nice= @rest.choices().users.level[row.level]?.nice ? '?'
					new_row.level_token= @rest.choices().users.level[row.level]?.token ? '?'
					table.push new_row
				@Table[tbl_nm]= table
			when 'Owner' # All projects and their owners
				data= @rest.get 'Project_team', f
				# Index the owners, then build projects w/owner data where available
				owners= {}
				members= {}
				owners[rec.project_id]= rec for rec in (data.owners ? [])
				members[rec.project_id]= rec for rec in (data.memberships ? [])
				results= []
				for row in data.projects when row.type is 1
					owner= owners[row.id] ? first_name: '', last_name: '', email: 'NONE'
					member= members[row.id] ? invited_as: 'NONE'
					new_row= $.extend {}, row, owner, member
					new_row.invited_as_nice= @rest.choices().members.invited_as[new_row.invited_as]?.nice ? ''
					new_row.invited_as_token= @rest.choices().members.invited_as[new_row.invited_as]?.token ? ''
					new_row.is_watching= if @rest.choices().members.invited_as[new_row.invited_as]?.token is 'watcher' then 'yes' else ''
					results.push new_row
				results.sort (a,b) ->
					if a.name.toLowerCase() is b.name.toLowerCase() then 0
					else if a.name.toLowerCase()> b.name.toLowerCase() then 1
					else -1
				@Table[tbl_nm]= results
			else super tbl_nm
		#_log2 f, 'after', @Table[tbl_nm]
		return
	fistLoadData: (oFist) ->
		f= "M:Sponsor.fistLoadData(#{oFist.getFistNm()})"
		switch oFist.getFistNm()
			when 'SponsorAddEmail'
				null # Leave empty
			when 'AddNewTeamUser'
				for row,ix in @sponsor_add_rows
					oFist.fb_HTML['FirstName__'+ix]= row.FirstName
					oFist.fb_HTML['LastName__'+ix]= row.LastName
					oFist.fb_HTML['TeamEmail__'+ix]= row.TeamEmail
					oFist.fb_HTML['LevelTeam__'+ix]= row.LevelTeam
			when 'ModifyTeamUser'
				rest_results= @_getSponsorData()
				for row in (rest_results.sponsors ? [])
					if row.id is @member_edit
						oFist.setFromDbValues row
						break
			else return super oFist
	fistGetFieldChoices: (oFist, field) ->
		f= 'M:Sponsor.fistGetFieldChoices:'+ oFist.getFistNm()+ ':'+ field
		_log2 f, oFist
		switch field
			when 'LevelTeam'
				results=( [val.sort, val.nice, val.token] for nm,val of @rest.choices().users.level when val.type is 'child')
				results.sort (a,b) -> a[0]- b[0]
				options:( rec[1] for rec in results), values: ( rec[2] for rec in results)
			else return super oFist, field
	_getSponsorData: ->
		f= "M:Sponsor._getSponsorData"
		return @c_sponsor_data if @c_sponsor_data
		@c_sponsor_data= @rest.get 'Sponsor', f
		
window.EpicMvc.Model.Sponsor= Sponsor # Public API
