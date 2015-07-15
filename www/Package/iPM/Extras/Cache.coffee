
# Keep project data in persitent local storage (for each end user)
# TODO GET A HASHKEY FROM SERVER TO REPRESENT USER (DON'T USE ID ANYMORE)
# Lifetime of object is logged in user's session
# Run longpolling that captures changes from server to be synced, for this logged in user
# Support loading and update actions of a model that needs access to one project at a time
#

class Cache
	constructor: (@user_id,@model_project_list_cb,@model_project_cb,@model_user_cb) ->
		@prefix= 'CACHE'
		@active_project= false
		@loading= @_PullProjects()
		@_DoChild() if not @loading
		endpoint= window.EpicMvc.Extras.options.PollEndpoint
		@poller= new window.EpicMvc.Extras.Poll endpoint, @state.cursor, @_HandleDeltas
		@poller.Start()
	Stop: -> # Clean up any resources
		@poller.Stop()

	GetProjectList: () ->
		@project_list
	GetProject: (prid) ->
		@active_project= false
		return false if prid is false # Unset active, was requested
		@active_project= prid
		return true if @loading is true # Special 'is loading' flag
		return @active_project= false if not (prid of @projects) # No such project
		return @projects[prid]
	AddProject: (prid,rec,make_active) -> # Caller has done an add/clone, and we'll push the delta when we see it
		@projects[prid]= rec
		@project_list[prid]= rec.project # TODO IS THIS THE RIGHT VALUES? DO I STORE THESE IN LOCAL-STORE?
		@active_project= prid if make_active is true

	_LsRemove: (what, what_id) ->
		f= 'E:Cache._LsRemove'
		return #TODO IMPLEMENT LOCALSTORAGE unless window.localStorage
		key= [@prefix, @user_id, what]
		key.push what_id if what_id?
		window.localStorage.removeItem key.join '_'
		return
	_LsPut: (what, what_id, value) ->
		f= 'E:Cache._LsPut'
		return #TODO IMPLEMENT LOCALSTORAGE unless window.localStorage
		key= [@prefix, @user_id, what]
		key.push what_id if what_id?
		window.localStorage.setItem (key.join '_'), JSON.stringify value
		return
	_LsGet: (what, what_id) ->
		f= 'E:Cache._LsGet'
		return {} #TODO IMPLEMENT LOCALSTORAGE unless window.localStorage
		key= [@prefix, @user_id, what]
		key.push what_id if what_id?
		js= window.localStorage.getItem key.join '_'
		return if js then JSON.parse js else {}
	_PullProjects: ->
		@projects= {}
		@project_list= {}
		# Do we have stuff in storage?
		@state= @_LsGet 'state'
		if not ('cursor' of @state)
			@state.cursor= null
			return true # We are 'loading', waiting on initial data
		@project_list= @_LsGet 'project_list'
		# For this version, keep all projects in memory
		(@projects[id]= @_LsGet 'project', id) for id of @project_list
		return false # We aren't loading, waiting for initial data

	_HandleDeltas: (data) =>
		f= 'E:Cache._HandleDeltas'
		#_log2 f, 'loading/active_project/data', @loading, @active_project, data
		# Look for cmd's inside data.project and data.user
		# After handling, let model know the nature of change
		was_loading= @loading

		reset_prid= []; reject_prid= []
		if data.project
			_log2 f, 'project', data.project
			for prid of data.project
				project= data.project[prid]
				# TODO GET ID TO BE PROJECT_ID IN MEMBERS RECORD
				rec.project_id = rec.id for rec in (project.members or []) when 'id' of rec #TODO
				active= (Number prid) is @active_project # TODO String VS Number
				exists= prid of @project_list
				switch project.cmd
					when 'reject'
						# Model: Ignore active; 'project_list' only (not 'project')
						#@model_project_list_cb 'reject', prid
						reject_prid.push (Number prid) if exists
						delete @projects[prid]
						delete @project_list[prid]
						@_LsRemove 'project', prid
						@_LsPut 'project_list', null, @project_list
					when 'reset'
						@_HandleProjectReset prid, project
						# Model: 'project reset' if active; 'project_list' if not previously existing
						#@model_project_list_cb 'reset', prid if not exists
						# TODO THE CALL TO _LIST_CB WORKED FOR SETTING PUBLIC-FLAG ON MOVE-FOLDER; CLEAN UP CODE IF NO OTHER ISSUES POP UP
						if true # TODO VERIFY RESET NEEDS TO GO TO MODEL_PROJECT_LIST_CB BECAUSE BY-REFERENCE LINKS BROKEN not exists
							reset_prid.push (Number prid)
						else
							@model_project_cb prid, msgs if active
						@_LsPut 'project', prid, @projects[prid]
						@_LsPut 'project_list', null, @project_list
					when 'merge'
						msgs= @_HandleProjectMerge prid, project
						# Model: when active, include 'msgs'
						@model_project_cb prid, msgs if active
						@_LsPut 'project', prid, @projects[prid]
						@_LsPut 'project_list', null, @project_list
					else alert "Unknown change.sync verb (#{project.cmd}) for project (#{prid})"
		if data.user and @model_user_cb
			_log2 f, 'user', data.user
			for id,rec of data.user when rec.cmd is 'merge'
				@model_user_cb rec.cmd, rec.user
		@loading= false
		@_LsPut 'state', null, cursor: data.cursor
		# Do this after setting @loading to false, to allow client to call back for project data
		@model_project_list_cb reset_prid, reject_prid if reset_prid.length or reject_prid.length or was_loading is true
		return true # Yes, continue to poll
	_HandleProjectReset: (prid,changes) ->
		@projects[prid]= project: {}, folders: {}, files: {}, members: {}, activities: []
		project= @projects[prid]
		$.extend true, project.project, changes.project # Clone
		(project.folders[rec.id]= $.extend true, {}, rec) for rec in changes.folders # Clone
		(project.files[rec.id]=   $.extend true, {}, rec) for rec in changes.files # Clone
		(project.members[rec.user_id]= $.extend true, {}, rec) for rec in changes.members # Clone
		project.activities.push $.extend true, {}, rec for rec in (changes.activities ? [])
		#TODO MEMBER REC INSTEAD W/MERGED PROJECT DATA MAYBE @project_list[prid]= @projects[prid].project
		#TODO @project_list[prid]= $.extend true, {}, @projects[prid].project, @projects[prid].members[@user_id] #TODO THIS CLONE WON'T REFLECT E.G. PROJECT NAME CHANGE
		@project_list[prid]= project.members[@user_id] or class: 20
		$.extend true, @project_list[prid], project.project
		@project_list[prid].project_id= project.project.id
		@_DoChild prid

	_HandleProjectMerge: (prid,changes) ->
		f= 'E:Cache._HandleProjectMerge:'+prid
		# Deal with cascading change types (disposal(delete-cascade), folder_id(move), perm(visibility)
		msgs= project: false, folders: [], files: [], members: [],  activities: []
		orig= @projects[prid]
		if changes.project
			msgs.project= true
		if changes.folders?.length
			_log2 f, 'folders', changes.folders.length
			for new_rec in changes.folders
				new_rec.folder_id= (Number new_rec.folder_id) if typeof new_rec.folder_id is 'string' #TODO DAVID-J WHY IS FOLDER_ID A STRING ON MERGE?
				old_rec= orig.folders[new_rec.id]
				ids= []
				file_ids= []
				cmd= 'UNKNOWN'
				perm_chg= false
				if old_rec is undefined
					cmd= 'add' # May be that it's just now visible
					orig.folders[new_rec.id]= $.extend true, {}, new_rec
					@_AddChild prid, 'folder', new_rec
				else if new_rec.disposal is 1
					cmd= 'delete'
					# TODO [ids, file_ids]= @_CascadeDeleteFolder prid, new_rec.id, 'both'
					child_folders= @projects[prid].folder_folders
					child_files= @projects[prid].folder_files
					child_annot= @projects[prid].file_annot
					RemoveFolderRecurse= (id) =>
						if id of child_files # Has file children
							for fiid in child_files[id]
								if fiid of child_annot # Has annot children
									for anid of child_annot[fiid]
										file_ids.push anid
										delete @projects[prid].files[anid]
									delete child_annot[fiid]
								file_ids.push fiid
								delete @projects[prid].files[fiid]
							delete child_files[id]
						if id of child_folders # Has folder children
							for child in child_folders[id]
								ids.push child
								RemoveFolderRecurse child
							delete child_folders[id]
						delete @projects[prid].folders[id]
					RemoveFolderRecurse new_rec.id
				else if 'folder_id' of new_rec and new_rec.folder_id isnt old_rec.folder_id
					cmd= 'move'
					perm_chg= new_rec.perm isnt old_rec.perm
					@_RmChild prid, 'folder', old_rec
					$.extend true, old_rec, new_rec
					@_AddChild prid, 'folder', new_rec
				else
					# TODO IF IT TYPE FLAG ONLY CHANGED, WOULD NEED TO E.G. _Rm/_AddChild ?
					cmd= 'change'
					$.extend true, old_rec, new_rec # Simple merge?
				if perm_chg and new_rec.perm is 6
					# If folder is 'see only other folders' remove files
					child_files= @projects[prid].folder_files
					child_annot= @projects[prid].file_annot
					id= new_rec.id
					if id of child_files # Has file children
						for fiid in child_files[id]
							if fiid of child_annot # Has annot children
								for anid of child_annot[fiid]
									file_ids.push anid
									delete @projects[prid].files[anid]
								delete child_annot[fiid]
							file_ids.push fiid
							delete @projects[prid].files[fiid]
						delete child_files[id]
				msgs.folders[new_rec.id]= cmd: cmd, ids: ids, file_ids: file_ids
		if changes.files?.length
			for new_rec in changes.files
				old_rec= orig.files[new_rec.id]
				ids= []
				cmd= 'UNKNOWN'
				if old_rec is undefined
					cmd= 'add' # May be that it's just now visible
					orig.files[new_rec.id]= $.extend true, {}, new_rec
					@_AddChild prid, 'file', new_rec
				else if new_rec.disposal is 1
					cmd= 'delete'
					ids= (@projects[prid].file_annot[old_rec.id] or [])
					for annot_id in ids
						delete @projects[prid].files[annot_id]
					delete @projects[prid].file_annot[old_rec.id]
					@_RmChild prid, 'file', old_rec
					delete @projects[prid].files[old_rec.id]
				else if 'folder_id' of new_rec and new_rec.folder_id isnt old_rec.folder_id
					cmd= 'move'
					@_RmChild prid, 'file', old_rec
					$.extend true, old_rec, new_rec
					@_AddChild prid, 'file', new_rec
					if new_rec.type is 1 then alert 'Unexpected folder_id change on annotation'
					ids= (@projects[prid].file_annot[new_rec.id] or [])
					for annot_id in ids
						@projects[prid].files[annot_id].folder_id= new_rec.folder_id
				else
					cmd= 'change'
					$.extend true, old_rec, new_rec # Simple merge
				msgs.files[new_rec.id]= cmd: cmd, ids: ids
		if changes.members?.length
			for new_rec in changes.members
				old_rec= orig.members[new_rec.user_id]
				ids= []
				cmd= 'UNKNOWN'
				if old_rec is undefined
					cmd= 'add'
					orig.members[new_rec.user_id]= $.extend true, {}, new_rec
				else if new_rec.disposal is 1
					cmd= 'delete'
					delete @projects[prid].members[old_rec.user_id]
				else
					cmd= 'change'
					$.extend true, old_rec, new_rec # Simple merge
				msgs.members[new_rec.user_id]= cmd: cmd, old_rec: old_rec, new_rec: new_rec
		if changes.activities?.length
			for new_rec in changes.activities
				orig.activities.push $.extend true, {}, new_rec
		_log2 f, 'msgs', msgs

	_RmChild: (prid,table,rec) -> # table: 'file' or 'folder'
		switch table
			when 'folder'
				parent= rec.folder_id
				p_table= 'folder_folders'
			when 'file'
				if rec.type is 1
					parent= rec.file_id
					p_table= 'file_annot'
				else
					parent= rec.folder_id
					p_table= 'folder_files'
		ixarray= @projects[prid][p_table][parent]
		ix= ixarray.indexOf rec.id
		ixarray.splice ix, 1 unless ix is -1
	_AddChild: (prid,table,rec) -> # table: 'file' or 'folder'
		switch table
			when 'folder'
				parent= rec.folder_id
				p_table= 'folder_folders'
			when 'file'
				if rec.type is 1
					parent= rec.file_id
					p_table= 'file_annot'
				else
					parent= rec.folder_id
					p_table= 'folder_files'
			else alert 'BORKEN 473638'
		@projects[prid][p_table][parent]?= []
		@projects[prid][p_table][parent].push rec.id
	_DoChild: (prid) ->
		f= 'E:Cache._DoChild:'+prid
		if prid? # Only one project requested
			list= [prid]
		else
			list= (id for id of @project_list)
		#_log2 f, 'list', list.join ','
		for prid in list
			tables= @projects[prid]
			$.extend @projects[prid], folder_folders: {}, folder_files: {}, file_annot: {}

			folders= @projects[prid].folder_folders
			for id,row of tables.folders
				folders[row.folder_id]?= []
				folders[row.folder_id].push row.id
			files= @projects[prid].folder_files
			annot= @projects[prid].file_annot # Array by parent file_id of id's
			for id,row of tables.files
				if row.type is 1
					annot[row.file_id]?= []
					annot[row.file_id].push row.id
				else # For now, only top level files (not annot) in folder_files
					files[row.folder_id]?= []
					files[row.folder_id].push row.id

window.EpicMvc.Extras.Cache= Cache # Public API

