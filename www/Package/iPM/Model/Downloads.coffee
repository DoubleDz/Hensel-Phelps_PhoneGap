
# TODO ASSOCIATE THE ZIP OBJECT WITH THE LOADER, SO WE CAN REMOVE IT'S EXISTANCE
class Downloads extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		super Epic, view_nm
		@downloads= {}
		@download_ids= []
		@prefix= 'download-'
		@in_progress= 0
	eventNewRequest: -> @Table= {}
	eventLogout: ->
		@Epic.renderer.UnloadMessage 'download' # Unset it
		return true
	action: (act,p) ->
		f= "M:Downloads::action(#{act})"
		_log f, p
		r= {}; i= new window.EpicMvc.Issue(); m= new window.EpicMvc.Issue()
		switch act
			when 'abort' # p.id # Stop a download instance
				id= if p.id then p.id else @active
				if id and @downloads[id]
					@downloads[id].oZip.Cancel()
					@_remove id
					delete @active
					r.success= 'SUCCESS'
				else r.success= 'FAIL'
			when 'choose_loader' # p.id # Remember a download instance
				id= p.id
				@active= id
				r.success= 'SUCCESS'
			when 'delete' # p.id # Remove a download instance
				id= if p.id then p.id else @active
				if id and @downloads[id]
					@_remove id
					delete @active
					r.success= 'SUCCESS'
				else r.success= 'FAIL'
			when 'download' # p.id (Parent folder to start, 0/empty for whole project), p.callback_class
				_log f, id: p.id, cbc: p.callback_class
				foid= if p.id then Number p.id else 0
				cbc= window.EpicMvc.Extras[p.callback_class]
				oDir= @Epic.getInstance 'Directory'
				# TODO prompt for include_versions
				include_versions= true
				[prid, folders, files, project_name]= oDir.getForDownload(include_versions)
				do (prid, foid, files, folders, cbc) =>
					setTimeout (=>
						oZip= new window.EpicMvc.Extras.Zip prid, foid
						curr_ids= (dir for dir in @download_ids when @downloads[dir].progress?.step isnt 'FINISH')
						new_id= @_newDownload oZip, prid
						cbo= new cbc oZip, prid, new_id
						oZip.Start files, folders, project_name, cbo, new_id, curr_ids, @prefix, include_versions
					), 10
				r.success= 'SUCCESS'
			else return super act, p
		@invalidateTables true
		[r, i, m]
	_remove: (id) ->
		@in_progress-= 1 if @downloads[id].progress?.step isnt 'FINISH'
		@download_ids.splice (@download_ids.indexOf id), 1
		delete @downloads[id]
		@Epic.renderer.UnloadMessage 'download' if @in_progress is 0
	loadTable: (tbl_nm) ->
		f= "M:Downloads::loadTable(#{tbl_nm})"
		#_log2 f
		switch tbl_nm
			when 'Loader' # List of processes doing downloads
				result= []
				for id in @download_ids
					row= @downloads[id].progress
					row.id= id # Handle for open/close/delete cmds
					result.push row
				@Table[tbl_nm]= result
			else super tbl_nm
		#_log2 f, 'after', @Table[tbl_nm]
		return
	_newDownload: (zip_object, project_id) ->
		id= @prefix+ @Epic.nextCounter()
		@downloads[id]= oZip: zip_object, project_id: project_id, progress: {
			step: 'START', files: '-', total_files: '-', bytes: 0, total_bytes: 0
			}, files: {}, file_list: [], file_response: {}
		@download_ids.push id
		@in_progress+= 1
		@Epic.renderer.UnloadMessage 'download', 'Leaving the page will stop all download activity'
		@invalidateTables ['Loader']
		return id
	downloadProgress: (id, data) ->
		f= 'M:Downloads.downloadProgress:'+id
		#_log f, data
		@downloads[id].progress= data
		@in_progress-= 1 if data.step is 'FINISH'
		@Epic.renderer.UnloadMessage 'download' if @in_progress is 0 # Clear the warning
		@invalidateTables ['Loader']
	fileProgress: (id, file_id, data) ->
		f= 'M:Downloads.fileProgress:'+id
		#_log f, file_id, data
		@downloads[id].file_list.push file_id if not @downloads[id].files[file_id]
		@downloads[id].files[file_id]= data
	fileResponse: (id, file_id, data) ->
		f= 'F:Downloads.fileResponse:'+id
		_log f, file_id, data
		response= data.files?[0] or id: -1, code: data.status, error: data.responseText
		if response.err then response= id: -1, code: response.err.code, error: response.err.message
		@downloads[id].file_response[file_id]= response
	replyCallback: (id,cb) ->
		@downloads[id].cb= cb

window.EpicMvc.Model.Downloads= Downloads # Public API
