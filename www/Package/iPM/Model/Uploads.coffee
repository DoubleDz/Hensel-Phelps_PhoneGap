
class Uploads extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		ss= active: false
		super Epic, view_nm, ss
		@uploads= {}
		@upload_ids= []
		@upload_retry_objects= []
	eventNewRequest: -> @Table= {}
	eventLogout: ->
		@Epic.renderer.UnloadMessage 'upload' # Unset it
		return true
	action: (act,p) ->
		f= "M:Uploads::action(#{act})"
		_log f, p
		r= {}; i= new window.EpicMvc.Issue(); m= new window.EpicMvc.Issue()
		switch act
			when 'open' # p.id
				id= p.id
				if @active isnt id
					@active= id
				r.success= 'SUCCESS'
			when 'close' # p.id
				@active= false
				r.success= 'SUCCESS'
			when 'confirm' # (optional)p.id, p.answer
				id= if p.id then p.id else @active
				cb= @uploads[id].cb # store in closure so we can remove @uploads[id]
				setTimeout (-> cb p.answer), 0
				@_remove id if not p.answer
				r.success= 'SUCCESS'
			when 'abort' # optional: p.id # Remove an upload instance
				id= p.id or @active
				if id and @uploads[id]
					@uploads[id].oLoad.Cancel()
					@_remove id
					r.success= 'SUCCESS'
				else r.success= 'FAIL'
			when 'delete' # p.id # Remove an upload instance
				id= p.id
				@_remove id
				r.success= 'SUCCESS'
			when 'delete_active_on_finish_clean' # p.id # Remove an upload instance
				id= @active
				if id not of @uploads
					r.success= 'NO_SUCH_ID'
					return [r, i, m]
				rec= @uploads[id]
				if rec.progress.step isnt 'FINISH'
					r.success= 'NOT_FINISHED'
					return [r, i, m]
				has_error= false
				for nm in rec.file_list
					file= rec.files[nm]
					if @uploads[@active].file_response[nm]?.id is -1
						has_error= true
						break
				if has_error is true
					r.success= 'HAS_ERROR'
					return [r, i, m]
				@_remove id
				r.success= 'SUCCESS'
			when 'retry_all' # @active, p.callback_class
				_log f, @active, @uploads[@active]
				prid= @uploads[@active].project_id
				callback_class= p.callback_class
				all_files= @uploads[@active].files
				file_list= (fid: fid, file: rec.file, parent_id: rec.parent_id for fid,rec of all_files when @uploads[@active].file_response[fid].id is -1)
				(@Epic.getInstance 'Directory').fileRetry @active, prid, file_list
				if file_list.length isnt 0
					do (file_list, prid, callback_class) =>
						setTimeout (=>
							@upload_retry_objects.push new window.EpicMvc.Extras.DropRetry file_list, prid, window.EpicMvc.Extras[callback_class]
							# TODO FIGURE OUT IF SOMEONE SHOULD BE HANGING ONTO NEW DROPRETRY OBJ
						), 0
					r.success= 'SUCCESS'
				else
					i.add 'NO_FILES_FOUND'
					r.success= 'EMPTY'
			else return super act, p
		@invalidateTables true
		[r, i, m]
	_remove: (id, no_retry) ->
		(@Epic.getInstance 'Directory').fileRetry id, @uploads[id].project_id, @uploads[id].file_list if no_retry isnt false
		@active= false if @active is id
		@upload_ids.splice (@upload_ids.indexOf id),1
		delete @uploads[id]
		@Epic.renderer.UnloadMessage 'upload' if @upload_ids.length is 0
	loadTable: (tbl_nm) ->
		f= "M:Uploads::loadTable(#{tbl_nm})"
		#_log2 f
		switch tbl_nm
			when 'Loader' # List of processes doing uploads
				result= []
				for id in @upload_ids
					row= @uploads[id].progress
					row.id= id # Handle for open/close/delete cmds
					result.push row
				@Table[tbl_nm]= result
			when 'Open' # The detail on the open loader, and it's file list
				result= []
				if @active and @uploads[@active]
					files= []
					has_error= 0
					for nm in @uploads[@active].file_list
						file= @uploads[@active].files[nm]
						file.has_error= if @uploads[@active].file_response[nm]?.id is -1 then 'yes' else ''
						has_error++ if file.has_error is 'yes'
						file.icon_ext= window.extToIconPostfix file.name
						files.push file
					result.push $.extend true, {}, @uploads[@active].progress, File: files, has_error: has_error
				else result.push {}
				@Table[tbl_nm]= result
			else super tbl_nm
		#_log2 f, 'after', @Table[tbl_nm]
		return
	newUpload: (load_object, project_id) ->
		id= 'upload-'+ @Epic.nextCounter()
		@uploads[id]= oLoad: load_object, project_id: project_id, progress: {}, files: {}, file_list: [], file_response: {}
		@Epic.renderer.UnloadMessage 'upload', 'Leaving the page will stop all upload activity'
		@upload_ids.push id
		@invalidateTables ['Loader']
		@active= id # Let's make this active, right away
		return id
	uploadProgress: (id, data) ->
		f= 'M:Uploads.uploadProgress:'+id
		#_log f, data
		@uploads[id].progress= data
		tbls= ['Loader']
		tbls.push 'Open' if id is @active
		@invalidateTables tbls
	uploadAbort: (id) ->
		@_remove id, true if id of @uploads # 'If' we never got going with this id before a failure (ie. folders-upload)
	fileProgress: (id, file_id, data) ->
		f= 'M:Uploads.fileProgress:'+id
		#_log f, file_id, data
		@uploads[id].file_list.push file_id if not @uploads[id].files[file_id]
		@uploads[id].files[file_id]= data
		if id is @active
			@invalidateTables ['Open']
	fileResponse: (id, file_id, data) ->
		f= 'F:Uploads.fileResponse:'+id
		_log f, file_id, data
		response= data.files?[0] or id: -1, code: data.status, error: data.responseText
		if response.err then response= id: -1, code: response.err.code, error: response.err.message
		@uploads[id].file_response[file_id]= response
	replyCallback: (id,cb) ->
		@uploads[id].cb= cb

window.EpicMvc.Model.Uploads= Uploads # Public API
