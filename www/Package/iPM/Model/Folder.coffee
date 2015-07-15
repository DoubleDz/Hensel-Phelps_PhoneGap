class Folder extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		ss=
			project_active: false
			folder_view_id: {} # Hash on project
			folder_edit_id: false
			file_edit_id: false
			upload_folder: false
			root_open: FORMS: false, PUBLIC: true, PRIVATE: true
			project_edit_id: false
			project_type: 1
			tab_profile: 'edit'
		super Epic, view_nm, ss
		@rest= window.EpicMvc.Extras.Rest # Static class
		@clip= folders: {}, files: {}, undofolders: [], undofiles: []
		@_resetProjectCache()
		@toggle_item= false
		@upload_file= {}
		@upload_response= {}
		@team_add_issue= false # Set to email of unknown user, for option to invite
		@team_add_open= false # Is hidden add-by-email showing?
		@team_filter_open= false
		@activity_filter_open= false
		@folder_filter_open= false
		@is_logged_in= false
		@eventLogin() if @rest.doToken() isnt false # TODO FIND WAY TO AVOID ANOTHER NETWORK CALL?
		@cache_pending= true
		@c_version_child= {}
		@tab_profile_choices= ['edit', 'projects', 'edit', 'password', 'extended', 'expose', 'subscription', 'sponsor', 'billing']
		@c_notice_text= false
		@file_signed_url= false
	eventNewRequest: () ->
		@team_add_issue= false
		delete @Table.MemberExtended # Don't cache this, since nothing updates it's values for us
		delete @Table.Owner # Don't cache this, since nothing updates it's values for us
	eventLogin: () ->
		return if @is_logged_in is true
		me_id=( @Epic.getViewTable 'User/Me')[0].id
		setTimeout (=>
			@cache= new window.EpicMvc.Extras.Cache me_id,
				@UpdateProjectListAsync, @UpdateProjectAsync,( @Epic.getInstance 'User').UpdateUserAsync
			), 0
		@is_logged_in= true
	eventLogout: () ->
		@is_logged_in= false
		@invalidateTables ['Notice']
		@cache?.Stop()
		return true
	action: (act,p) ->
		f= "M:Folder.action(#{act})"
		_log2 f, p, ({}[n]=@[n] for n of @ss)
		r= {}
		i= new window.EpicMvc.Issue @Epic, @view_nm, act
		m= new window.EpicMvc.Issue @Epic, @view_nm, act
		switch act
			when 'url_team' then r.url= "team-#{@project_active}"
			when 'url_team_context'
					@_resetProjectCache() if Number p.context isnt @project_active
					@project_active= Number p.context
			when 'url_landing'
				r.url=
					if @project_active
						"folders-#{@project_active}"+
						if @folder_view_id[@project_active]
							":#{@folder_view_id[@project_active]}"
						else ''
					else ''
			when 'url_landing_context'
				vals= p.context.split ':' ; [oldP,oldF]= [@project_active,@folder_view_id[@project_active]]
				@project_active= Number vals[0] if vals[0]?.length and Number vals[0]
				if vals[1]?.length and Number vals[1]
					@folder_view_id[@project_active]= Number vals[1]
				else
					delete @folder_view_id[@project_active] # When not specified, go back to root
				# TODO MAY NEED TO DO THE BELOW WHEN ASYNC LOAD OCCURS
				if @project and @project.id is @project_active and @folder_view_id[@project_active]?
					if not @c_folders[@folder_view_id[@project_active]]
						delete @folder_view_id[@project_active]
				@Table= {} if oldP isnt @project_active or oldF isnt @folder_view_id[@project_active]
				@_resetProjectCache() if oldP isnt @project_active
			when 'project_type' # p:type=(template/project/toggle)
				was= @project_type
				@project_type=
					switch p.type
						when 'template' then 0
						when 'project' then 1
						when 'toggle' then (if was is 0 then 1 else 0)
				if was isnt @project_type
					@root_open= FORMS: false, PUBLIC: true, PRIVATE: true
					@project_active= false
					@Table= {}
				r.success= 'SUCCESS'
			when 'open_close' # Root folder open/close for all projects
				# p:type=(open/close/toggle) p:folder:(PUBILC/PRIVATE/FORMS)
				was= @root_open[p.folder]
				@root_open[p.folder]=
					switch p.type
						when 'open' then true
						when 'close' then false
						when 'toggle' then not @root_open[p.folder]
				@Table= {} if was isnt @root_open[p.folder]
				r.success= 'SUCCESS'
			when 'toggle' # Open/close a folder 'drawer' of a certain type (e.g. actions/activity/permissions,etc.)
				if @toggle_item is false
					@toggle_item= type: p.type, id: Number p.id
				else if @toggle_item.id is Number p.id # Same folder
					if @toggle_item.type is p.type
						@toggle_item= false # Untoggle same 'type'
					else @toggle_item.type= p.type # switch 'type'
				else @toggle_item= type: p.type, id: Number p.id # Switching folders
				@c_version_child= {}
				@Table= {}
				r.success= 'SUCCESS'
			when 'choose_upload_folder'
				if @upload_folder isnt Number p.upload_folder
					@upload_folder= Number p.upload_folder; @Table= {}
				r.success= 'SUCCESS'
			when 'default_first_project', 'choose_first_project'
				projects= @_getMemberRecs()
				sort= (id: id, name: rec.name for id,rec of projects when rec.type is @project_type and rec.pending isnt true)
				sort.sort (a,b) ->
					if a.name.toLowerCase() is b.name.toLowerCase() then 0
					else if a.name.toLowerCase()> b.name.toLowerCase() then 1
					else -1
				id= sort[0]?.id
				if id
					if typeof @project_active isnt 'number' or act is 'choose_first_project'
						if @project_active isnt Number id
							@_resetProjectCache()
							@project_active= Number id
							m.add 'COULD_BE_MANAGER' if @c_member[@project_active].class < @c_member[@project_active].invited_as
							@invalidateTables true
					r.success= 'SUCCESS'
					@invalidateTables ['Member']
				else r.fail= 'NO_PROJECTS'
			when 'choose_project_view'
				upgrading= false
				if @project_active isnt Number p.id
					projects= @_getMemberRecs()
					valid= false
					(valid= true; break) for id,entry of projects when entry.project_id is Number p.id
					if valid
						@_resetProjectCache()
						@root_open= FORMS: false, PUBLIC: true, PRIVATE: true
						@project_active= Number p.id
						if @c_member[@project_active].class is 0 # Restricted Case
							result= @rest.post "User/me/Project/#{@project_active}/unrestrict", f
							if result.SUCCESS is true
								@c_member[@project_active].class = result.new_class
							else
								@rest.makeIssue m, result
								upgrading= true # TODO: Verify Result is a true upgrade result
						if not upgrading and @c_member[@project_active].class < @c_member[@project_active].invited_as
							m.add 'COULD_BE_MANAGER'
						@c_version_child= {}
						@invalidateTables true
						r.success= 'SUCCESS'; r.note= 'CHANGE'
						r.upgrade= 'YES' if upgrading
					else r.fail= 'INVALID_PROJECT'; i.add 'INVALID_PROJECT'
				else r.success= 'SUCCESS'; r.note= 'SAME'
			when 'choose_folder_view' # p.id(false/0 or folder_id)
				changed= false
				if p.id is false or p.id is '0' # False/0 means remove (go to root)
					if @folder_view_id[@project_active]
						changed= true; delete @folder_view_id[@project_active]
				else if Number p.id # Must have a value
					if @folder_view_id[@project_active] isnt Number p.id
						changed= true; @folder_view_id[@project_active]= Number p.id
				_log2 changed, p.id, @folder_view_id[@project_active]
				@invalidateTables true if changed
				r.success= 'SUCCESS'
			when 'choose_folder_edit'
				@folder_edit_id= if p.id is false then false else Number p.id
				(@Epic.getFistInstance 'Folder').clearValues()
				@Table= {}
				r.success= 'SUCCESS'
			when 'choose_file_edit'
				@file_edit_id= if p.id is false then false else Number p.id
				(@Epic.getFistInstance 'File').clearValues()
				@Table= {}
				r.success= 'SUCCESS'
			when 'choose_permission' #passing p.id, p.folder, p.perm[None/Viewer/Contributor/Collaborator], p.descend(yes/no)
				usid= Number p.id; foid= Number p.folder; prid= @project_active
				resource= "User/#{usid}/Project/#{prid}/Folder/#{foid}/setpermission"
				# params: type:{none/view/contribute/collaborate}, descend_flag(yes/no)
				map_perm_rest= None: 'none', Viewer: 'view', Contributor: 'contribute', Collaborator: 'collaborate'
				map_perm_val= Viewer: 5, Contributor: 4, Collaborator: 3
				@_getTeamPerms() # In case some 'reset' cleared our cache
				result= @rest.post resource, f, type: map_perm_rest[p.perm], descend_flag: p.descend
				if result.SUCCESS
					delete @c_team_perms
					r.success= 'SUCCESS'
					@Table= {}
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'delete_folder'
				if @folder_edit_id is false then r.success= 'NO CONTEXT'; return [r, i, m]
				endp= 'Project/'+ @project_active+ '/Folder/'+ @folder_edit_id+ '/delete'
				result= @rest.post endp, f
				if result.SUCCESS is true
					@c_folders[@folder_edit_id].disposal= 1 # Let Cache finish removal
					@folder_edit_id= false
					@Table= {}
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
			when 'save_folder' # Folder form
				if @folder_edit_id is false then r.success= 'NO CONTEXT'; return [r, i, m]
				oF = @Epic.getFistInstance 'Folder'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				endp= 'Project/'+ @project_active+ '/Folder/'+ @folder_edit_id+ '/rename'
				result= @rest.post endp, f, fv
				if result.SUCCESS is true
					@c_folders[@folder_edit_id].name= fv.name
					@folder_edit_id= false
					@Table= {}
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
			when 'delete_file'
				if @file_edit_id is false then r.success= 'NO CONTEXT'; return [r, i, m]
				endp= 'Project/'+ @project_active+ '/File/'+ @file_edit_id+ '/delete'
				result= @rest.post endp, f
				if result.SUCCESS is true
					@c_files[@file_edit_id].disposal= 1 # Let Cache finish removal
					@file_edit_id= false
					@Table= {}
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
			when 'save_file' # File form
				if @file_edit_id is false then r.success= 'NO CONTEXT'; return [r, i, m]
				oF = @Epic.getFistInstance 'File'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post "Project/#{@project_active}/File/#{@file_edit_id}/rename", f, fv
				if result.SUCCESS is true
					@c_files[@file_edit_id].name= fv.name
					@file_edit_id= false
					@Table= {}
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
			when 'add_folder' # Folder form
				oF = @Epic.getFistInstance 'Folder'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post "/Project/#{@project_active}/Folder", f,
					name: fv.name, folder_id: @upload_folder, counter: @project.delta_cnt
				if result.SUCCESS is true
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
			when 'add_file' # File form
				oF = @Epic.getFistInstance 'File'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post 'File', f,
					name: fv.name, size: fv.size, folder_id: @folder_view_id[@project_active]
				if result.SUCCESS is true
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
			when 'get_file_url'
				response= @rest.get "/Project/#{@project_active}/File/#{p.id}/inline", 'S3Open()'
				if not ('signed_url' of response)
					alert 'S3Open() bad response: '+ JSON.stringify response
					return false
				else
					@file_signed_url= response.signed_url
					@Table= {}
					r.success= 'SUCCESS'
			when 'choose_project_edit'
				@project_edit_id= if p.id is false then false else Number p.id
				@Table= {}
				r.success= 'SUCCESS'
			when 'clone_project' # CloneProject form (use current project_edit_id for project_id to clone)
				oF = @Epic.getFistInstance 'CloneProject'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				fv.project_id= @project_edit_id
				result= @rest.post 'User/me/Project', f, fv
				if result.SUCCESS is true
					@c_member[result.project_id]=
						name: result.name, project_id: result.project_id, invited_as: result.invited_as, type: 1, pending: true
					table= project: @c_member[result.project_id], folders: {}, files: {}, file_annot: [], members: {}, activities: [] #members: self?
					@cache.AddProject result.project_id, table
					for rec in result.restricted_users
						m.add 'RESTRICTED_MEMBER_ADDED', [rec.first_name, rec.last_name, rec.email]
					@Table= {}
					r.success= 'SUCCESS'; r.project_id= result.project_id
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					_log2 f, 'NOPE', result:result, i:i, r:r
					return [r, i, m]
			when 'add_project' # Project form
				oF = @Epic.getFistInstance 'Project'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post 'User/me/Project', f, fv
				if result.SUCCESS is true
					@c_member[result.project_id]=
						name: result.name, project_id: result.project_id, invited_as: result.invited_as, type: 1, pending: true
					table= project: @c_member[result.project_id], folders: {}, files: {}, file_annot: [], members: {}, activities: [] #members: self?
					@cache.AddProject result.project_id, table
					@Table= {}
					r.success= 'SUCCESS'; r.project_id= result.project_id
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					_log2 f, 'NOPE', result:result, i:i, r:r
					return [r, i, m]
			when 'add_template' # Template form
				oF = @Epic.getFistInstance 'Template'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				result= @rest.post 'User/me/Template', f, fv
				if result.SUCCESS is true
					@c_member[result.project_id]=
						name: result.name, project_id: result.project_id, invited_as: result.invited_as, type: 0, pending: true
					table= project: @c_member[result.project_id], folders: {}, files: {}, file_annot: [], members: {}, activities: [] #members: self?
					@cache.AddProject result.project_id, table
					@Table= {}
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					_log2 f, 'NOPE', result:result, i:i, r:r
					return [r, i, m]
			when 'delete_project' # @project_edit_id
				result= @rest.post "Project/#{@project_edit_id}/delete", f
				if result.SUCCESS is true
					delete @c_member[Number @project_edit_id]
					@_resetProjectCache true if @project_edit_id is @project_active
					@invalidateTables ['Team','User']
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					_log2 f, 'NOPE', result:result, i:i, r:r
					return [r, i, m]
			when 'rename_project' # @project_edit_id, ProjectRename form
				oF = @Epic.getFistInstance 'ProjectRename'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				_log2 f, 'check i', $.extend true, {}, i
				fv = oF.getDbFieldValues()
				result= @rest.post "Project/#{@project_edit_id}/update", f, fv
				if result.SUCCESS is true
					@c_member[Number @project_edit_id].name= fv.name
					@Table= {}
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
					_log2 f, 'NOPE', result:result, i:i, r:r
					return [r, i, m]
			when 'add_team_open', 'add_team_close'
				@team_add_open= act is 'add_team_open'
				@invalidateTables ['TeamAdd']
			when 'filter_team_toggle'
				@team_filter_open= not @team_filter_open
				@invalidateTables ['TeamFilter']
			when 'filter_team_open', 'filter_team_close'
				@team_filter_open= act is 'filter_team_open'
				@invalidateTables ['TeamFilter']
			when 'filter_activity_toggle'
				@activity_filter_open= not @activity_filter_open
				@invalidateTables ['ActivityFilter']
			when 'filter_activity_open', 'filter_activity_close'
				@activity_filter_open= act is 'filter_activity_open'
				@invalidateTables ['ActivityFilter']
			when 'filter_folder_toggle'
				@folder_filter_open= not @folder_filter_open
				@invalidateTables ['FolderFilter']
			when 'filter_folder_open', 'filter_folder_close'
				@folder_filter_open= act is 'filter_folder_open'
				@invalidateTables ['FolderFilter']
			when 'add_member', 'change_member', 'ping_member' # p.id (or fist: TeamAddEmail), p.as(member/manager)
				if not p.id # Use p.email
					oF = @Epic.getFistInstance 'TeamAddEmail'
					i.call oF.fieldLevelValidate p # Will populate DB side
					if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
					fv = oF.getDbFieldValues()
					result= @rest.post "User/email/Project/#{@project_active}/makemember" , f, invited_as: p.as, email: fv.email
				else
					result= @rest.post "User/#{p.id}/Project/#{@project_active}/makemember" , f, invited_as: p.as
				if result.SUCCESS is true
					if act is 'ping_member'
						m.add 'PING_MEMBER'
					else if result.class is 0 # Restricted Class Case
						m.add 'RESTRICTED_MEMBER_ADDED'
					else if result.class < result.invited_as
						m.add 'RESTRICTED_MANAGER_ADDED'
					# Update comes via delta-logic, dynamically
					if result.user_id of @c_team # Change
						$.extend @c_team[Number result.user_id], result
					else # Add
						@c_team[Number result.user_id]= result
					# Handle special case where our role as member has changed (i.e. as owner we add/change another as owner)
					me= @c_member[@project_active] # shortcut
					if result.caller.new_invited_as isnt me.invited_as or result.caller.new_class isnt me.class
						if result.project_transfered
							m.add 'PROJECT_TRANSFER_SUCCESS'
						me.invited_as= result.caller.new_invited_as
						me.class= result.caller.new_class
						@invalidateTables true # Everything changes
					@invalidateTables ['Team','User']
					r.success= 'SUCCESS'
				else if act is 'add_member' and not p.id and result.match /^"Error: REST_404_USERS/
					@team_add_issue= fv.email
					r.success= 'NO_SUCH_USER'
					@invalidateTables ['TeamAdd']
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'remove_member' # p.id REST: /User/:usid/Project/:prid/?
				result= @rest.post "User/#{p.id}/Project/#{@project_active}/deletemember" , f
				if result.SUCCESS is true
					@c_team[Number p.id].disposal= 1 # Leave it for Cache to manipulate
					@invalidateTables ['Team','User']
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'clear_clip'
				tbls= ['FORMS', 'PUBLIC','PRIVATE','Clipboard', 'Folder', 'File'] # TODO Detect Folder/File only if there were any?
				@clip= folders: {}, files: {}, undofolders: [], undofiles: []
				@invalidateTables tbls
				r.success= 'SUCCESS'
			when 'remove_file_from_clip' # p.id(file-id)
				from_file_id= Number p.id
				if from_file_id of @clip.files
					delete @clip.files[ from_file_id]
					@invalidateTables ['FORMS', 'PUBLIC', 'PRIVATE', 'File', 'Clipboard']
				r.success= 'SUCCESS'
			when 'remove_folder_from_clip' # p.id(folder-id)
				from_folder_id= Number p.id
				if from_folder_id of @clip.folders
					delete @clip.folders[ from_folder_id]
					@invalidateTables ['FORMS', 'PUBLIC', 'PRIVATE', 'Folder', 'Clipboard']
				r.success= 'SUCCESS'
			when 'remove_undofile_from_clip' # p.id(undofile-id)
				from_undofile_id= Number p.id
				clip_ix= @clip.undofiles.indexOf from_undofile_id
				if clip_ix isnt -1
					@clip.undofiles.splice clip_ix, 1
					@invalidateTables ['Clipboard']
				r.success= 'SUCCESS'
			when 'remove_undofolder_from_clip' # p.id(undofolder-id)
				from_undofolder_id= Number p.id
				clip_ix= @clip.undofolders.indexOf from_undofolder_id
				if clip_ix isnt -1
					@clip.undofolders.splice clip_ix, 1
					@invalidateTables ['Clipboard']
				r.success= 'SUCCESS'
			when 'folder_to_clip' # p.from(folder-id)
				from_id= Number p.from
				if from_id not of @clip.folders
					@clip.folders[ from_id]= @c_folders[ from_id]
					@clip.folders[from_id].project_id= @project_active
					@invalidateTables ['FORMS', 'PUBLIC', 'PRIVATE', 'Folder', 'Clipboard']
				r.success= 'SUCCESS'
			when 'file_to_clip' # p.from(file-id)
				from_id= Number p.from
				if from_id not of @clip.files
					@clip.files[ from_id]= @c_files[ from_id]
					@clip.files[from_id].project_id= @project_active
					@invalidateTables ['FORMS', 'PUBLIC', 'PRIVATE', 'File', 'Clipboard']
				r.success= 'SUCCESS'
			when 'undofile_to_clip' # p.from(activty-id)
				if (@clip.undofiles.indexOf Number p.from) is -1
					@clip.undofiles.push (Number p.from)
					@invalidateTables ['Clipboard']
				r.success= 'SUCCESS'
			when 'undofolder_to_clip' # p.from(activty-id)
				if (@clip.undofolders.indexOf Number p.from) is -1
					@clip.undofolders.push (Number p.from)
					@invalidateTables ['Clipboard']
				r.success= 'SUCCESS'
			when 'move_file' # p.from(file-id), p.to(folder-id), p.type("version")
				from_file_id= Number p.from
				to_folder_id= Number p.to
				if to_folder_id is @c_folders.FORMS.id
					if @c_files[from_file_id].ext isnt 'pdf'
						i.add 'PDF_ONLY'
						r.success= 'FAIL'
						return [r, i, m]
				data= new_folder_id: to_folder_id
				from_project= @project_active
				if from_file_id of @clip.files and @clip.files[from_file_id].project_id isnt @project_active
					from_project= @clip.files[from_file_id].project_id
					data.new_prid= @project_active
				# Check with the server
				action= if p.type is 'version' then 'version' else 'move'
				result= @rest.post "Project/#{from_project}/File/#{from_file_id}/#{action}", f, data
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
				# May need to remove from clipboard
				delete @clip.files[ from_file_id]
				# Make local update
				@c_files[from_file_id].folder_id= to_folder_id unless 'new_prid' of data
				@invalidateTables ['FORMS', 'PUBLIC','PRIVATE','File','Clipboard']
				r.success= 'SUCCESS'
			when 'recover_file' # p.from(activity-id)
				from_undofile_id= Number p.from
				# xref p.from as activity.id
				found= false
				for rec in @c_activities
					if rec.id is from_undofile_id
						found= true
						from_file_id= rec.object.id
						break
				if not found
					@rest.makeIssue i, '"M_MISSING_ACTIVITY"', p.from
					r.success= 'FAIL'
					return [r, i, m]
				# Check with the server
				result= @rest.post "Project/#{@project_active}/File/#{from_file_id}/recover", f
				if result.SUCCESS isnt true
					if result.match /^"Error: REST_403_PARENT_DISPOSED/
						r.success= 'PARENT_DISPOSED'
					else
						@rest.makeIssue i, result
						r.success= 'FAIL'
					return [r, i, m]
				# Make local update
				m.add 'RECOVERED_FILE_TO_ORIGINAL_PARENT', [rec.object.name]
				r.success= 'SUCCESS'
			when 'recover_file_to' # p.from(activity-id), p.to(folder-id)
				from_undofile_id= Number p.from
				to_folder_id= Number p.to
				# xref p.from as activity.id
				found= false
				for rec in @c_activities
					if rec.id is from_undofile_id
						found= true
						from_file_id= rec.object.id
						break
				if not found
					@rest.makeIssue i, '"M_MISSING_ACTIVITY"'
					r.success= 'FAIL'
					return [r, i, m]
				# Check with the server
				result= @rest.post "Project/#{@project_active}/File/#{from_file_id}/recover", f, new_foid: to_folder_id
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
				# May need to remove from clipboard
				clip_ix= @clip.undofiles.indexOf from_undofile_id
				@clip.undofiles.splice clip_ix, 1 if clip_ix isnt -1
				# Make local update
				# TODO PUT MORE STUFF IN HERE TO SIMULATE ENTRY UNTIL DELTA ARIVES
				@c_files[from_file_id]= id: from_file_id, folder_id: to_folder_id, name: rec.object.name
				@invalidateTables ['FORMS', 'PUBLIC','PRIVATE','File','Clipboard']
				r.success= 'SUCCESS'
				m.add 'RECOVERED_FILE_TO_PROJECT', [rec.object.name]
			when 'move_folder' # p.from(folder-id), p.to(folder-id)
				from_folder_id= Number p.from
				to_folder_id= Number p.to
				data= new_folder_id: to_folder_id
				from_project= @project_active
				if from_folder_id of @clip.folders and @clip.folders[from_folder_id].project_id isnt @project_active
					from_project= @clip.folders[from_folder_id].project_id
					data.new_prid= @project_active
				# Check with the server
				result= @rest.post "Project/#{from_project}/Folder/#{from_folder_id}/move", f, data
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
				# May need to remove from clipboard
				delete @clip.folders[ from_folder_id]
				# Make local update
				@c_folders[from_folder_id].folder_id= to_folder_id unless 'new_prid' of data
				@invalidateTables ['FORMS', 'PUBLIC','PRIVATE','Folder','Clipboard']
				r.success= 'SUCCESS'
			when 'recover_folder_to' # p.from(activity-id), p.to(folder-id)
				from_undofolder_id= Number p.from
				to_folder_id= Number p.to
				found= false
				for rec in @c_activities
					if rec.id is from_undofolder_id
						from_folder_id= rec.object.id
						found= true
						break
				if not found
					@rest.makeIssue i, '"M_MISSING_ACTIVITY"'
					r.success= 'FAIL'
					return [r, i, m]
				# Check with the server
				result= @rest.post "Project/#{@project_active}/Folder/#{from_folder_id}/recover",
					f, new_foid: to_folder_id
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
					return [r, i, m]
				# May need to remove from clipboard
				clip_ix= @clip.undofolders.indexOf from_undofolder_id
				@clip.undofolders.splice clip_ix, 1 if clip_ix isnt -1
				# Make local update
				# TODO PUT MORE STUFF IN HERE TO SIMULATE ENTRY UNTIL DELTA ARIVES
				@c_folders[from_folder_id]= id: from_folder_id, folder_id: to_folder_id, name: rec.object.name
				@invalidateTables ['FORMS', 'PUBLIC','PRIVATE','Folder','Clipboard']
				r.success= 'SUCCESS'
				m.add 'RECOVERED_FOLDER_TO_PROJECT', [rec.object.name]
			when 'recover_folder' # p.from(activity-id)
				from_undofolder_id= Number p.from
				found= false
				for rec in @c_activities
					if rec.id is from_undofolder_id
						from_folder_id= rec.object.id
						found= true
						break
				if not found
					@rest.makeIssue i, '"M_MISSING_ACTIVITY"'
					r.success= 'FAIL'
					return [r, i, m]
				# Check with the server
				result= @rest.post "Project/#{@project_active}/Folder/#{from_folder_id}/recover", f
				if result.SUCCESS isnt true
					if result.match /^"Error: REST_403_PARENT_DISPOSED/
						r.success= 'PARENT_DISPOSED'
					else
						@rest.makeIssue i, result
						r.success= 'FAIL'
					return [r, i, m]
				m.add 'RECOVERED_FOLDER_TO_ORIGINAL_PARENT', [rec.object.name]
				r.success= 'SUCCESS'
			when 'start_os_upload' # p.input_obj, p.callback_class(string), id-is-@upload_folder [THIS HANDLES DIALOG BOX UPLOAD]
				parent_folder= p.id ? @upload_folder
				accept= if parent_folder is @c_folders.FORMS.id then ['pdf'] else []
				drop= new window.EpicMvc.Extras.DropOSDialog p.input_obj, @project_active, parent_folder,
					window.EpicMvc.Extras[p.callback_class], accept
				if drop.fileHandler() is false
					r.success= 'FAIL'
				else
					r.success= 'SUCCESS'
			when 'start_upload' # p.event, p.to(folder-id), p.callback_class(string), {p.type("version")}
				is_version= p.type is 'version'
				parent_folder= if p.type isnt 'version' then (Number p.to) else @c_files[p.to].folder_id
				accept= if parent_folder is @c_folders.FORMS.id then ['pdf'] else []
				if is_version
					items=( rec for rec in p.event.dataTransfer.items when rec.kind is 'file')
					entry= items[0].webkitGetAsEntry()
					if items.length isnt 1 or entry.isDirectory
						is_version= false
					else if @c_files[p.to].ext.toLowerCase() isnt (entry.name.split '.').pop().toLowerCase()
						r.success= 'FAIL'
						i.add 'FILE_VERSION_EXTENSION_NOT', [@c_files[p.to].ext]
						return [r, i, m]
				drop_type= if not is_version then false else parent_id:(Number p.to), type:'version'
				cb= window.EpicMvc.Extras[p.callback_class]
				drop= new window.EpicMvc.Extras.Drop @project_active, parent_folder, cb, accept, drop_type
				if (drop.dropHandler p.event) is false
					r.success= 'FAIL'
				else
					r.success= 'SUCCESS'
			when 'choose_tab_profile' # p.tab (any value in @tab_choices)
				if @tab_profile isnt p.tab
					@tab_profile= p.tab
					@invalidateTables ['Options']
				r.success= 'SUCCESS'
			when 'stop_watch_project' # p.id(project-id)
				prid= Number p.id
				result= @rest.post "User/me/Project/#{prid}/deletemember", f, {}
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
				else
					delete @c_member[prid]
					@_resetProjectCache true if prid is @project_active
					@invalidateTables true # Needed to reset 'Options', 'Breadcrumb', etc.
					r.success= 'SUCCESS'
			when 'start_watch_project' # p.id(project-id)
				prid= Number p.id
				result= @rest.post "User/me/Project/#{prid}/makeadminmember", f
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
				else
					# Simulate the project until change-sync updates us
					@c_member[prid]=
						name: (p.name ? 'MISSING'), project_id: prid, invited_as: 30, type: 1, pending: true
					table= project: @c_member[prid], folders: {}, files: {}, file_annot: [], members: {}, activities: [] #members: self?
					@cache.AddProject result.project_id, table
					@invalidateTables  ['Member','MemberExtended']
					r.success= 'SUCCESS'
			when 'activate_version' #p.id, p.current
				result= @rest.post "Project/#{@project_active}/File/#{p.current}/revertversion", f, revert_file_id: p.id
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
				else
					result.versions[0].version_name = 'TBD' # TODO Remove when server supplies this field
					@c_version_child[p.current].unshift result.versions[0]
					@invalidateTables ['File', 'FORMS', 'PUBLIC','PRIVATE' ]
					r.success= 'SUCCESS'
			when 'delete_version' #p.id
				result= @rest.post "Project/#{@project_active}/File/#{p.id}/delete", f, {}
				if result.SUCCESS isnt true
					@rest.makeIssue i, result
					r.success= 'FAIL'
				else
					r.success= 'SUCCESS'
			when 'notify_send' # p:form:ComposeNotify
				oF = @Epic.getFistInstance 'ComposeNotify'
				i.call oF.fieldLevelValidate p # Will populate DB side
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv = oF.getDbFieldValues()
				fv.link_flag= if fv.link_flag is '1' then 'YES' else 'NO'
				fv.link_hash= if @project_active then "folders-#{@project_active}" else ''
				# Add to fv, the selected user list
				p.user_list?= {}
				fv.user_list= (usid for usid of p.user_list).join ',' if fv.send_option is 'list'
				if fv.send_option is 'list' and not fv.user_list.length
					i.add 'NOTHING_SELECTED'
					r.success= 'FAIL'
					return [r, i, m]
				result= @rest.post "Project/#{@project_active}/emailmembers" , f, fv
				if result.SUCCESS is true
					m.add 'SUCCESS', [result.recipient_count]
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			else return super act, p
		[r, i, m]
	loadTable: (tbl_nm) ->
		f= 'M:Folder.loadTable:'+tbl_nm
		#_log2 f
		@_getProjectData()
		switch tbl_nm
			when 'Me' # My member record
				table= []
				defaults= is_manager: '', is_owner: '', is_admin: ''
				my_rec=( @Epic.getViewTable 'User/Me')[0]
				my_id= my_rec.id
				new_row= defaults
				if (member= @c_team[Number my_id])
					new_row= $.extend true, {}, member, defaults
					map= @rest.choices().members.invited_as[new_row.invited_as]
					new_row.invited_as_nice=  map.nice
					new_row.invited_as_token= map.token
					new_row.is_manager= 'yes' if new_row.invited_as_token is 'manager'
					new_row.is_owner= 'yes' if new_row.invited_as_token is 'owner'
					new_row.is_admin= 'yes' if new_row.invited_as_token is 'watcher'
				table.push new_row
				@Table[tbl_nm]= table
			when 'Clipboard'
				files= []
				for ix,rec of @clip.files
					new_row= $.extend {}, rec
					new_row.icon_ext= window.extToIconPostfix new_row.name, new_row.ext
					files.push new_row
				undofiles= []
				for ix in @clip.undofiles
					for rec in @c_activities
						if rec.id is ix
							undofiles.push id: rec.id, name: rec.object.name, icon_ext: window.extToIconPostfix rec.object.name
							break
				undofolders= []
				for ix in @clip.undofolders
					for rec in @c_activities
						if rec.id is ix
							undofolders.push id: rec.id, name: rec.object.name
							break
				table= [
					is_empty: ''
					Folder: (rec for ix,rec of @clip.folders)
					File: files
					UndoFolder: undofolders
					UndoFile: undofiles
				]
				table[0].is_empty= 'yes' if table[0].Folder.length is 0 and files.length is 0 and undofolders.length is 0 and undofiles.length is 0
				#_log2 f, table
				@Table[tbl_nm]= table
			when 'User'
				table= []
				results= @_getUserRecs().users
				for row in results
					new_row= $.extend true, {}, row, on_team: ''
					new_row.on_team= 'yes' if new_row.id of @c_team
					table.push new_row
				@Table[tbl_nm]= table
			when 'TeamAdd'
				table= []
				table.push
					issue: if @team_add_issue is false then '' else 'yes'
					issue_email: @team_add_issue
					open: if @team_add_open is true then 'yes' else ''
				@Table[tbl_nm]= table
			when 'TeamFilter'
				table= []
				table.push
					open: if @team_filter_open is true then 'yes' else ''
				@Table[tbl_nm]= table
			when 'ActivityFilter'
				table= []
				table.push
					open: if @activity_filter_open is true then 'yes' else ''
				@Table[tbl_nm]= table
			when 'FolderFilter' # TODO CONSIDER REMOVING OLD SEARCH ON/OFF SETTINGS FOR FOLDER, ACTIVITY, TEAM
				table= []
				table.push
					open: if @folder_filter_open is true then 'yes' else ''
				@Table[tbl_nm]= table
			when 'FolderFilterList'
				folders= []
				files= []
				if @cache_pending isnt true
					(folders.push rec) for id,rec of @c_folders when rec.id isnt 0 and rec.id isnt -1 and rec.folder_id isnt 0
					for id,rec of @c_files when rec.id isnt 0 and rec.folder_id isnt 0
						files.push $.extend {}, rec, icon_ext: window.extToIconPostfix rec.name, rec.ext
				@Table[tbl_nm]= [ Folder: folders, File: files ]
			when 'Team'
				my_rec=( @Epic.getViewTable 'User/Me')[0]
				my_id= my_rec.id
				results= []
				now= new Date().getTime()
				for usid,rec of @c_team when rec.invited_as isnt 30
					row= $.extend {}, rec
					row.recent= if Date.parse(rec.modified)> now- 900 then 'yes' else ''
					row.email?= '' # Non-Owner/Mgr users don't get this field populated
					map= @rest.choices().members.invited_as[rec.invited_as]
					row.invited_as_nice=  map.nice
					row.invited_as_token= map.token
					row.is_me= if rec.user_id is my_id then 'yes' else ''
					row.is_project_restricted= if rec.class is 0 then 'yes' else ''
					row.is_manager_restricted= if rec.class < rec.invited_as then 'yes' else ''
					results.push row
				results.sort (a,b) ->
					if a.invited_as isnt b.invited_as then return b.invited_as- a.invited_as
					a_name= a.last_name+ a.first_name
					b_name= b.last_name+ b.first_name
					if a_name is b_name then 0
					else if a_name> b_name then 1
					else -1
				@Table[tbl_nm]= results
			when 'Template'
				results= []
				for id,rec of @_getMemberRecs() when rec.type is 0
					row= $.extend {}, rec, active: false, is_manager: '', is_owner: 'yes', is_pending: ''
					row.active= true if rec.project_id is @project_active
					row.is_pending= 'yes' if rec.pending is true
					results.push row
				results.sort (a,b) ->
					if a.name.toLowerCase() is b.name.toLowerCase() then 0
					else if a.name isnt '_WELCOME' and (b.name is '_WELCOME' or a.name.toLowerCase() > b.name.toLowerCase()) then 1
					else -1
				@Table[tbl_nm]= results
			when 'Member', 'MemberExtended'
				my_rec=( @Epic.getViewTable 'User/Me')[0]
				my_id= my_rec.id
				# For now, added 'MemberExtended' to grab fields that I don't get from change-sync (yet?)
				memberRecs= if tbl_nm is 'Member' then @_getMemberRecs() else @_getMemberRecsExtended()
				results= []
				for id,rec of memberRecs when rec.type is @project_type
					row= $.extend {}, rec, active: false, is_manager: '', is_owner: '', is_admin: '', is_pending: '', is_exposed: ''
					row.active= true if rec.project_id is @project_active
# 					rec.class?= 0; rec.invited_as # Future proof, allow class if given to us, else use invited-as
					row.is_manager= 'yes' if rec.class is 10
					row.is_owner= 'yes' if rec.invited_as is 20
					row.is_admin= 'yes' if rec.class is 30
					row.is_pending= 'yes' if rec.pending is true
					row.is_exposed= 'yes' if rec.contact_flag is 1
					row.is_project_restricted= if rec.class is 0 then 'yes' else ''
					row.is_manager_restricted= if rec.class < rec.invited_as then 'yes' else ''
					results.push row
				results.sort (a,b) ->
					if a.name.toLowerCase() is b.name.toLowerCase() then 0
					else if a.name.toLowerCase()> b.name.toLowerCase() then 1
					else -1
				@Table[tbl_nm]= results
			when 'Options'
				view_id= @folder_view_id[@project_active]
				table= [
					cache_pending: if @cache_pending is true then 'yes' else ''
					cache_pending_project: if @c_member?[@project_active]?.pending is true then 'yes' else ''
					type: if @project_type is 0 then 'Template' else if @project_type is 1 then 'Project' else 'Undefined'
					is_template: if @project_type is 0 then 'yes' else ''
					active_project: @project_active # false when not yet chosen a project
					UploadEndpoint: @_getUploadEndpoint()+ "#{@project_active}/#{@upload_folder}"
					is_root: if view_id then '' else 'yes'
					active_folder: @folder_view_id[@project_active] ? 0 # Zero when at 'root'
					can_edit: '', can_add: '', can_upload: '', hide_FORMS: '', hide_PRIVATE: '', hide_PUBLIC: ''
					is_upload_FORMS: ''
					file_signed_url: if @file_signed_url then @file_signed_url else ''
				]
				for nm in @tab_profile_choices
					table[0]['tab_profile_'+nm]= if @tab_profile is nm then 'yes' else ''
				if not @cache_pending
					$.extend table[0],
						is_public: if view_id and @c_folders[view_id].public then 'yes' else ''
						is_private: if view_id and !@c_folders[view_id].public then 'yes' else ''
				if view_id and not @cache_pending # we are in a folder, check perm
					perm= @c_folders[view_id].perm
					switch perm
						when 2 then table[0].can_edit= 'yes'; table[0].can_add= 'yes'; table[0].can_upload= 'yes'
						when 3
							table[0].can_add= 'yes'; table[0].can_upload= 'yes'
							me_id=( @Epic.getViewTable 'User/Me')[0].id
							table[0].can_upload= 'yes' if @c_folders[view_id].user_id is me_id
						when 4 then table[0].can_upload= 'yes'
				else # At root
					table[0].hide_FORMS= 'yes' if not @root_open.FORMS
					table[0].hide_PRIVATE= 'yes' if not @root_open.PRIVATE
					table[0].hide_PUBLIC= 'yes' if not @root_open.PUBLIC
					table[0].can_upload= 'yes' if @c_folders.PUBLIC.perm is 2 # TODO CHANGE HTML/JS TO USE EACH ROOT FOLDER INSEAD
				table[0].is_upload_FORMS= 'yes' if @upload_folder is @c_folders.FORMS.id
				@Table[tbl_nm]= table
			when 'FORMS', 'PUBLIC', 'PRIVATE'
#PROJECT
				table= [
					Folder: if @root_open[tbl_nm] then @_getFolderTable @c_folders[tbl_nm].id else []
					File:   if @root_open[tbl_nm] then @_getFileTable   @c_folders[tbl_nm].id else []
					Crumb:  [ name: tbl_nm ]
					Options: [ active_folder: @c_folders[tbl_nm].id ] # TODO VERIFY WE STILL USE THIS
					active_folder: @c_folders[tbl_nm].id
					hide: if @root_open[tbl_nm] then '' else 'yes'
					can_edit: '', can_add: '', can_upload: ''
				]
				table[0].is_empty=( table[0].Folder.length+ table[0].File.length is 0)
				perm= @c_folders[tbl_nm].perm
				switch perm
					when 2 then table[0].can_edit= 'yes'; table[0].can_add= 'yes'; table[0].can_upload= 'yes'
					when 3
						table[0].can_add= 'yes'; table[0].can_upload= 'yes'
						me_id=( @Epic.getViewTable 'User/Me')[0].id
						table[0].can_upload= 'yes' if @c_folders[tbl_nm].user_id is me_id
					when 4 then table[0].can_upload= 'yes'
				@Table[tbl_nm]= table
			when 'Project'
				results= @project
#PROJECT
				results.url= "#{window.location.origin}#{window.location.pathname}#folders-#{@project.id}"
				@Table[tbl_nm]= [results]
			when 'Folder'
				@Table[tbl_nm]= @_getFolderTable @folder_view_id[@project_active]
			when 'File'
				@Table[tbl_nm]= @_getFileTable @folder_view_id[@project_active]
			when 'Crumb'
				if @project_active and not @cache_pending
					results= [ id= @folder_view_id[@project_active] ? 0 ]
					while ( id= @c_folders[id].folder_id) isnt 0
						results.push id if @c_folders[id].folder_id isnt 0 # Not FORMS/PUBLIC/PRIVATE folders
					results.push 0 if @folder_view_id[@project_active]
					@Table[tbl_nm]=( @c_folders[ results[ i]] for i in [results.length- 1..0])
				else @Table[tbl_nm]= []
			when 'Details'
				results= [ @c_folders[@folder_view_id[@project_active] ? 0] ]
				@Table[tbl_nm]= results
			when 'FolderDetails'
				results= [ @c_folders[@folder_edit_id] ]
				@Table[tbl_nm]= results
			when 'FileDetails'
				results= [ @c_files[@file_edit_id] ]
				@Table[tbl_nm]= results
			when 'Notice'
				results= []
				results.push text: @c_notice_text if @c_notice_text isnt false
				@c_notice_text= false
				@Table[tbl_nm]= results
			when 'Activity'
				results= []
				for rec in @c_activities
					timestamp= Date.parse rec.created
					dt= new Date timestamp
					new_rec=
						created: rec.created, verb: rec.verb, timestamp: timestamp
						date: window.make_date dt
						time: window.make_time dt
						user_name: rec.actor.name
						table: rec.object.type, description: rec.object.name
						destination: '', is_recoverable: '', id: rec.id
					if rec.object.type is 'file' or rec.object.type is 'folder'
						#TODO new_rec.destination= 'a-parent-folder-name'
						if rec.verb is 'Removed' # TODO ALSO CHECK OWNER/MGR/ADMIN OR AUTH_USER-IS-ACTOR
							new_rec.is_recoverable= 'yes'
					# Versioning
					if rec.verb is 'Added' and rec.object.type is 'file' and rec.object.file_type is 0 and rec.target?.type is 'file'
						new_rec.table= 'version'
						new_rec.destination= rec.target.name
					results.push new_rec
				results.sort (a,b) ->
					if a.timestamp is b.timestamp then 0
					else if a.timestamp< b.timestamp then 1
					else -1
				# TODO CONSIDER DROPPING OLDER ENTRIES AS NEW ONES SHOW UP (FROM CACHE, TO AVOID MEMORY ISSUES?)
				# TODO ANOTHER OPTION, IS TO HAVE A FILTER IN THE STATE, AND AFTER THE FILTER, APPLY 100 LIMIT ON I/F/DISPLAY
				@Table[tbl_nm]= results.slice 0, 100 # Since we only get 100 from delta on reset, just show this much in I/F
			else super tbl_nm
		return
	fistLoadData: (oFist) ->
		f= 'M:Folder.fistLoadData:'+ oFist.getFistNm()
		_log2 f, 'oFist/defs', oFist, oFist.getFieldsDefs()
		switch oFist.getFistNm()
			when 'Folder'
				if @folder_edit_id isnt false  # have context?
					oFist.setFromDbValues @c_folders[@folder_edit_id]
				else oFist.clearValues() # TODO FIGURE OUT WHY I HAVE TO DO THIS, IF I DO 'rename existing folder;cancel;add folder'
			when 'File'
				if @file_edit_id isnt false  # have context?
					oFist.setFromDbValues @c_files[@file_edit_id]
				else oFist.clearValues()
			when 'ProjectRename'
				if @project_edit_id isnt false # Have context?
					for id,member of @_getMemberRecs()
						if member.project_id is @project_edit_id
							oFist.setFromDbValues member
							break
				else oFist.clearValues()
			when 'ComposeNotify'
				return
			when 'Project', 'TeamAddEmail', 'Template', 'CloneProject'
				return # Empty, for add; Update this when doing 'edit proejct' (name field?)
			else return super oFist
	fistGetFieldChoices: (oFist, field) ->
		f= 'M:Folder.fistGetFieldChoices:'+ oFist.getFistNm()+ ':'+ field
		_log2 f, oFist
		switch field
			when 'Template'
				templates= @rest.get 'Template', f
				results= (rec for rec in templates.templates when rec.name isnt '_WELCOME')
				results.sort (a,b) ->
					if a.name is b.name then 0
					else if a.name isnt '_EMPTY' and (b.name is '_EMPTY' or a.name> b.name) then 1
					else -1
				results[0].name= oFist.getFieldsDefs()[field].custom.first
				options:( rec.name for rec in results), values:( String rec.id for rec in results)
			else return super oFist, field
	# External entry points
	UpdateProjectListAsync: (adds,removes) => # Cache's longpoll detected chgs to user's project list
		f= 'M:Folder.UpdateProjectListAsync'
		_log2 f, 'adds,removes', (adds.join ','), (removes.join ','), 'project_active=', @project_active
		@c_member= @cache.GetProjectList()
		for prid in adds
			if @c_member[prid].class is 0
				extra= if @cache_pending is true then 'exists' else 'was added'
				@c_notice_text = 'A Project ' + extra + ' where you have restrictions'
				@invalidateTables ['Notice']
				break
		click= false
		if @cache_pending is true
			@UpdateProjectAsync @project_active, {} if @project_active
			click= 'Async.loaded'
			tbl_list= true # Everything changes
		else
			tbl_list= ['Member','Template','Options'] # Added options for single-pending-cache-update (on add/clone project)
			if @project_active in adds
				click= 'Async.reset_project'
				@_resetProjectCache()
				@_getProjectData()
			else if @project_active in removes
				click= 'Async.deleted_project'
				@_resetProjectCache()
			#alert f+ '-'+ click
		@cache_pending= false
		if click isnt false
			@invalidateTables true, ['TeamAdd']
			@Epic.makeClick false, click, name: 'TODO', false
		else
			@invalidateTables tbl_list
	UpdateProjectAsync: (prid,msgs) => # Cache's longpoll detected chgs to active project
		f= 'M:Folder.UpdateProjectAsync'
		_log2 f, 'prid/msgs', prid, msgs, 'project_active=', @project_active
		#return false if @project is null or @project.id isnt prid # TODO SHOULD NOT HAPPEN
		@_getProjectData()
		# TODO SOMEDAY LOOK AT ACTUAL CHANGES TO DETECT CERTAIN TABLE CHANGES (BREADCRUMB, ETC.)
		@invalidateTables true, ['TeamAdd']
		return
	# Local common logic
	_getFolderTable: (parent_folder_id) ->
		f= 'M:Folder._getFolderTable:'+ parent_folder_id
		#_log2 f, @toggle_item, @c_folders[parent_folder_id]
		results= []
		return results if parent_folder_id is -1
		def_can_edit= ''; def_can_add= ''; def_can_upload= ''
		perm_check= false
		perm= @c_folders[parent_folder_id].perm
		switch perm
			when 2 then def_can_edit= 'yes'; def_can_add= 'yes'; def_can_upload= 'yes'
			when 3
				def_can_add= 'yes'; def_can_upload= 'yes'
				me_id=( @Epic.getViewTable 'User/Me')[0].id
				perm_check= true
			when 4 then def_can_upload= 'yes'
		perm_map= 3:'have_collab',4:'have_contrib',5:'have_viewer'
		now = new Date().getTime()
		recent= now - 300 # within the last 5 minutes
		myself=( @Epic.getViewTable 'Directory/Me')[0] or invited_as: 0
		perms= if myself.invited_as < 10 then {} else @_getTeamPerms()
		for id,row of @c_folders when row.folder_id is parent_folder_id
			continue if (Number id) of @clip.folders
			new_row= $.extend true, {}, row,
				drawer_open: '', activity_open: '', actions_open: '', users_open: '', edit: '', Team:[]
				can_edit: def_can_edit, can_add: def_can_add, can_upload: def_can_upload
			new_row[@toggle_item.type+ '_open']= 'yes' if row.id is @toggle_item.id
			for meid,me_rec of @c_team when me_rec.invited_as < 10 #skips managers and owners
				if myself.invited_as < 10
					continue if me_rec.user_id isnt myself.user_id
					perms[id]?= {}
					perms[id][meid]= row.perm if row.public is 0 or (row.public is 1 and row.perm< 5)
				team_rec=
					id: meid, perm: 0, modified: me_rec.modified, time_stamp: me_rec.time_stamp
					have_none: 'yes', have_viewer: '', have_contrib: '', have_collab: ''
					name: @c_team[meid].first_name+ ' '+ @c_team[meid].last_name
				if perms?[id]?[meid]
					team_rec[perm_map[perms[id][meid]]]= 'yes'
					team_rec.have_none= ''
					team_rec.perm= perms[id][meid]
				new_row.Team.push team_rec
			new_row.edit= 'yes' if row.id is @folder_edit_id
			new_row.drawer_open= 'yes' if new_row.edit or new_row[@toggle_item.type+ '_open'] is 'yes'
			new_row.can_edit = 'yes' if perm_check and row.user_id is me_id
			#_log2 f, 'new_row', new_row
			results.push new_row
			new_row.Team.sort (a,b) ->
				if a.name is b.name then 0
				else if a.name> b.name then 1
				else -1
		results.sort (a,b) ->
			if a.name is b.name then 0
			else if a.name> b.name then 1
			else -1
	_getFileTable: (parent_folder_id) ->
		f= 'M:Folder._getFileTable:'+ parent_folder_id
		_log2 f, @toggle_item, @c_folders[parent_folder_id]
		results= []
		return results if parent_folder_id is -1
		def_can_edit= ''
		perm_check= false
		perm= @c_folders[parent_folder_id].perm
		switch perm
			when 2 then def_can_edit= 'yes'
			when 3
				me_id=( @Epic.getViewTable 'User/Me')[0].id
				perm_check= true
		results= []
		for id,row of @upload_file when parent_folder_id is Number row.parent_id
			row.modified?= '' # TODO SET TO 'NOW' FOR NOW?
			new_row= $.extend true, {}, row,
				drawer_open: '', activity_open: '', actions_open: '', users_open: '',
				annot_open: '', edit: '', pending: 'yes', uploading: 'yes', has_error: ''
				can_edit: '', has_versions: '', versions_open: ''
			new_row.size= Number row.total
			new_row.uploading= '' if row.subevent is 'END'
			new_row.has_error= 'yes' if @upload_file[id]?.id is -1
			new_row.icon_ext= window.extToIconPostfix new_row.name, new_row.ext
			results.push new_row
		for id,row of @c_files when row.folder_id is parent_folder_id and row.type is 0
			continue if (Number id) of @clip.files
			new_row= $.extend true, {}, row,
				drawer_open: '', activity_open: '', actions_open: '', users_open: '', annot_open: ''
				edit: '', pending: '', uploading: '', versions_open: ''
				can_edit: def_can_edit, Annot: [], Version: [], has_versions: ''
			new_row[@toggle_item.type+ '_open']= 'yes' if row.id is @toggle_item.id
			new_row.edit= 'yes' if row.id is @file_edit_id
			new_row.drawer_open= 'yes' if new_row.edit or new_row[@toggle_item.type+ '_open'] is 'yes'
			new_row.icon_ext= window.extToIconPostfix new_row.name, new_row.ext
			new_row.can_edit = 'yes' if perm_check and row.user_id is me_id
			new_row.has_versions= 'yes' if row.type is 0 and row.file_id isnt null
			if row.id of @c_annot_child
				for anid in @c_annot_child[row.id] when anid of @c_files
					annot_row= $.extend true, {}, @c_files[anid], can_edit: def_can_edit, edit: ''
					annot_row.edit= 'yes' if annot_row.id is @file_edit_id
					annot_row.icon_ext= window.extToIconPostfix annot_row.name, annot_row.ext
					new_row.can_edit = 'yes' if perm_check and annot_row.user_id is me_id
					urec= @c_team[annot_row.user_id] or last_name: 'Member', first_name: 'Non'
					annot_row.last_name= urec.last_name; annot_row.first_name= urec.first_name
					annot_row.modified_int= Date.parse annot_row.modified # for quick sort by date
					new_row.Annot.push annot_row
				new_row.Annot.sort (a,b) -> b.modified_int- a.modified_int # Newst to oldest
			@_getFileVersions(@project_active, new_row.id) if new_row.versions_open is 'yes'
			if row.id of @c_version_child
				for vr_rec in @c_version_child[row.id]
					ver_row= $.extend true, {}, vr_rec, is_active: ''
					ver_row.is_active= 'yes' if ver_row.id of @c_files
					ver_row.icon_ext= window.extToIconPostfix ver_row.name, ver_row.ext
					urec= @c_team[ver_row.user_id] or last_name: 'Member', first_name: 'Non'
					ver_row.last_name= urec.last_name; ver_row.first_name= urec.first_name
					new_row.Version.push ver_row
			results.push new_row
		results.sort (a,b) ->
			if a.name is b.name then 0
			else if a.name> b.name then 1
			else -1
	_getProjectData: ->
		f= 'M:Folder._getProjectData'
		#_log2 f, 'top:pa/ca/pr', @project_active, @cache, @project
		return unless @project_active and @cache # No context
		@_resetProjectCache() if @project?.id isnt @project_active # Changed active project
		if @project is null # Not already loaded
			# Convert raw data to indexed strutures for our use
			# Raw is, one project, of Project: {id,name,type}, Arrays of Folders, Files, Members, Actvities
			tables= @cache.GetProject @project_active # False=deleted; True=still-loading; else project-data
			_log2 f, 'tables', tables
			(@project_active= false; return) if tables is false
			return if tables is true # Pending load # TODO TEST THIS
			@cache_pending= false
			@project= tables.project
			@c_folders= tables.folders
			if not (0 of @c_folders)
				$.extend true, @c_folders,
					0: { id: 0, name: @project.name, folder_id: 0 }
					FORMS: id: -1
					PUBLIC: id: -1 # For projects w/o PUBLIC/PRIVATE records?
					PRIVATE: id: -1
				for id,row of @c_folders when row.id isnt 0
					@c_folders[row.name]= row if row.folder_id is 0 # Root folders by-name
			@c_files= tables.files
			@c_annot_child= tables.file_annot # Array by parent file_id of id's
			# TODO WE ALSO HAVE FOLDER_FOLDERS AND FOLDER_FILES PARENT LIST IN TABLES IF NEEDED
			@c_team= tables.members
			@c_activities= tables.activities

		# Misc reaction to other state information

		# Attempt to clear out file-upload shadow entries
		for fid,file of @upload_response
			if file.id of @c_files
				delete @upload_file[fid]
				delete @upload_response[fid]
		# Was the active view deleted?
		if @folder_view_id[@project_active]? and not @c_folders[@folder_view_id[@project_active]]
			delete @folder_view_id[@project_active]
			@invalidateTables true, ['TeamAdd']
			@Epic.makeClick false, 'Async.deleted_folder', name: 'TODO', false
	_getUploadEndpoint: ->
		window.EpicMvc.Extras.options.UploadEndpoint #TODO Verify '/' on the end
	_resetProjectCache: (reset_project_active)->
		@cache?.GetProject false
		@project_active= false if reset_project_active
		@project= null
		@c_folders=
			0: id: 0, folder_id: 0
			FORMS: id: -1
			PUBLIC: id: -1
			PRIVATE: id: -1
		@c_files= {}
		@c_annot_child= {}
		@c_team= {}
		@c_team_perms= false
		@c_activities= []
		tbls= ['Team','User' ,'Activity' ]
		@clip.undofiles= []; @clip.undofolders= []; tbls.push 'Clipboard' # TODO IS THIS OK ANYTIME?
		@invalidateTables tbls
	_getUserRecs: () -> # All Users in the network (for add-member)
		f= 'M:Folder._getUserRecs'
		#_log2 f, @c_user
		return @c_user if @c_user
		@c_user= @rest.get 'User', f
	_getMemberRecs: () -> # All projects I'm a member of
		f= 'M:Folder._getMemberRecs'
		#_log2 f, @c_member
		@c_member?= {}
	_getFileVersions: (project_id, fiid) -> # All versions of a particular file
		return if fiid of @c_version_child
		f= 'M:Folder._getFileVersions'
		results= @rest.get "Project/#{project_id}/File/#{fiid}/version"
		_log2 f, results, @c_version_child
		@c_version_child[fiid]= results.files ? []
	_getMemberRecsExtended: () -> # All projects I'm a member of (Fresh from API w/all fields available)
		f= 'M:Folder._getMemberRecsExtended'
		results= @rest.get "User/me/Project"
		#_log2 f, results
		results.projects ? {} # Note: not currently indexed by project_id
	_doIndexTeam: (team) ->
	_getTeamPerms: () ->
		f= 'M:Folder._getTeamPerms'
		#_log f, @c_team_perms, @project_active
		return @c_team_perms if @c_team_perms
		return {} if not @project_active
		# I don't have a me.id on templates
		me=( @Epic.getViewTable 'User/Me')[0]
		return {} if not @c_team[me.id] or @c_team[me.id].invited_as < 10
		results= @rest.get "User/TODO/Project/#{@project_active}/permission"
		return {} if not results.permissions
		c_team_perms= {}
		for rec in results.permissions
			c_team_perms[rec.folder_id]?= {}
			c_team_perms[rec.folder_id][rec.user_id]= rec.type
		@c_team_perms=c_team_perms
	fileRetry: (id, prid, file_list) -> #@file_list:[fid:id,file:file,parent_id:foid ...] -or- [id....]
		f= 'M:Folder.fileRetry:'+id
		_log2 f, file_list
		for rec in file_list
			fid= ''+ id+ ':'+ (rec.fid or rec)
			delete @upload_response[fid]
			delete @upload_file[fid]
		@invalidateTables true, ['TeamAdd']

	fileResponse: (id, file_id, data) ->
		fid= ''+ id+ ':'+ file_id
		f= 'M:Folder.fileResponse:'+fid
		_log2 f, 'data,u_f[fid]', data, @upload_file[fid]
		response= data.files?[0] or
			id: false, code: data.status, alt_code: '',
			error: if data.responseText[0] is '{' then (JSON.parse data.responseText) else  data.responseText
		if response.err then response= id: false, code: response.err.code, error: response.err.message ? response.err.msg
		if response.error?.msg then response.alt_code= response.error.code; response.error= response.error.msg
		if response.error?.message then response.error= response.error.message
		@upload_response[fid]= response
		return
	fileProgress: (id, file_id, data) ->
		fid= ''+ id+ ':'+ file_id
		f= 'M:Folder.fileProgress:'+fid
		#_log2 f, file_id, data
		project_id = Number data.project_id
		parent_id = Number data.parent_id
		if data.subevent is 'END' and @upload_response[fid].id is false
			data.id= -1; data.code= @upload_response[fid].code; data.error= @upload_response[fid].error
		@upload_file[fid]= data
		invalidate= []
		if project_id is @project_active
			if @folder_view_id[project_id]
				invalidate.push 'File' if parent_id is @folder_view_id[project_id]
			else
				if parent_id is @c_folders['PUBLIC'].id then invalidate.push 'PUBLIC'
				else if parent_id is @c_folders['PRIVATE'].id then invalidate.push 'PRIVATE'
				else if parent_id is @c_folders['FORMS'].id then invalidate.push 'FORMS'
		@invalidateTables invalidate if invalidate.length
		return
	foldersUploaded: (id,project_id,parent_id,ids_list,folders_info) ->
		f= 'F:Folder.foldersUploaded'
		_log f, id, project_id, parent_id, ids_list, folders_info
		# Drop of folder hierarchy; temp insert into our display until delta
		return if project_id isnt @project_active # TODO SHOULD WE ASSUME CURRENT VIEWED PROJECT?
		parent= @c_folders[parent_id]
		for foid,ix in ids_list
			rec= folders_info[ix]
			@c_folders[foid]=
				id: foid, name: rec.name, folder_id: if rec.ix is 0 then parent_id else ids_list[rec.ix- 1]
				modifed: '', perm: parent.perm, public: parent.public # TODO WHAT ELSE CAN TMP BE COPIED FROM PARENT?
		@invalidateTables (@_whichTables parent_id)
		return
	_whichTables: (folder_id) ->
		return [ 'FORMS' ,'PUBLIC' ,'PRIVATE' ,'Folder' ] # TODO FIGURE OUT WHAT ACTUAL VIEW-TABLES ARE AFFECTED
	getForDownload: (include_versions)-> # return: [prid, folders, files]
		f= 'M:Folder.getForDownload'
		if include_versions
			results= @rest.get "Project/#{@project_active}", f, include_versions: 1
			r_folders= {}
			for row in results.folders
				r_folders[row.id]= row
			$.extend true, r_folders,
				0: { id: 0, name: @project.name, folder_id: 0 }
				FORMS: id: -1
				PUBLIC: id: -1 # For projects w/o PUBLIC/PRIVATE records?
				PRIVATE: id: -1
			r_files= {}
			for row in results.files
				r_files[row.id]= row
			[@project_active, r_folders, r_files, results.project.name]
		else
			[@project_active, @c_folders, @c_files, @project.name]
	getActiveProjectList: -> # Admin uses this
		@cache?.GetProjectList() ? {}

window.EpicMvc.Model.Folder= Folder # Public API

