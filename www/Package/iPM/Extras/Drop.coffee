class DropOSDialog
	constructor: (@file_input_obj, @prid, @foid, @cb_class, accept) ->
		@drop= new Drop @prid, false, @cb_class, accept
		@files= @file_input_obj.files
		@file_list= (file: file, parent_id: @foid for file in @files)
	fileHandler: ->
		@drop.fileHandler @file_list

window.EpicMvc.Extras.DropOSDialog= DropOSDialog # Public API

class DropRetry
	constructor: (@file_list, @prid, @cb_class) ->
		@drop= new Drop @prid, false, @cb_class
		@drop.fileHandler @file_list

window.EpicMvc.Extras.DropRetry= DropRetry # Public API

# Callback: function(step,counters,last)
# step: Token string per @step_types below
# counters: Hash of counts: total_xxx are the sum of entries found on disk; xxxx are 'sent' counts
# last: is true/false if this is the last progress notification at this 'step'
#
# Callback notes:
# User can also 'CANCEL', 'CANCEL_EMPTY' (if not files/fodlers found) and maybe 'CANCEL_ABORT' to @cb
# If @cb gets CANCEL_xxx then no further calls will be made to this upload
# Implementation notes
# @cancel when false should shut down async processes, so check for this in e.g. setTimeout or callbacks
class Drop
	constructor: (@prid, @parent_foid, @cb_class, accept, @drop_type) ->
		f= 'E:Drop.constructor'
		_log f, 'prid/parent_foid/accept', @prid, @parent_foid, accept, @drop_type
		@cbo= new @cb_class @, @prid
		@cb= @cbo.progress
		@rest= window.EpicMvc.Extras.Rest
		@cancel= false
		@old_cb= @cb
		@step_types= ['START', 'COUNT_ENTRIES', 'COUNT_BYTES', 'UPLOAD_FOLDERS', 'UPLOAD_FILES', 'FINISH' ]
		@step_before_confirm= 'COUNT_BYTES'
		@step= 0
		@counters= total_folders: 0, total_files: 0, total_bytes: 0, folders: 0, files: 0, bytes: 0, pending: 0, total_percent: '0%'
		@final= [] # {ix:0, name:''}... for folder creation
		@final_dirs= [] # Matches 'final' offset but has 'DirectoryEntry' object of this dir
		@final_files= {} # FileEntry list match final_dirs's index (i.e. final_dirs[5] has files final_files[5])
		@folder_ids= []
		@last_ix= @final_dirs.length
		@top_list= []
		@top_files= []
		@step_count_progress_called= false
		@step_upload_folders_called= false
		@progress_last_data= false
		@uploads_active= 0
		@uploads_todo_list= []
		@uploads_xhr= {}
		@accept= accept ? [] # Should be e.g. ['pdf']
	_cancel: ->
		@cancel= true
		@cb= ->
		xhr.abort() for ix,xhr of @uploads_xhr
		return
	_unique: () -> window.EpicMvc.Epic.nextCounter()
	Cancel: -> @_cancel()
	fileHandler: (file_list_with_parent_ids) -> #[ file: file, parent_id: folder_id ...]
		f= 'E:Drop.fileHandler'
		_log f, file_list_with_parent_ids
		return if not @_Progress 'START'
		# Initialize state using list of files
		for rec,ix in file_list_with_parent_ids
			# Weed out non @accept file types
			continue if @accept.length and (@accept.indexOf (rec.file.name.split '.').pop().toLowerCase()) is -1
			(@final_files[ix]= [rec.file]; @folder_ids.push rec.parent_id)
		keys= (key for key of @final_files)
		if keys.length is 0
			@cb 'CANCEL_EMPTY', null, null, accept: @accept
			@_cancel()
			return false
		return if not @_Progress 'COUNT_BYTES'
		@counters.total_files= @counters.pending= keys.length
		(@counters.total_bytes+= rec[0].size+ 1) for ix,rec of @final_files
		@_StepCountComplete()

	dropHandler: (evt) ->
		f= 'E:Drop.dropHandler'
		_log f,"@parent_foid",@parent_foid
		if @parent_foid is false
			@parent_foid = $(evt.target).attr('data-folder')
			_log f,"from target, @parent_foid",@parent_foid
		items=( rec for rec in evt.dataTransfer.items when rec.kind is 'file')
		new_items= []
		for i in [0...items.length]
			# Weed out non @accept file types
			entry= items[i].webkitGetAsEntry()
			continue if @accept.length and entry.isDirectory
			continue if @accept.length and (@accept.indexOf (entry.name.split '.').pop().toLowerCase()) is -1
			new_items.push items[i]
		if @drop_type and @drop_type.type is 'version'
			if new_items.length isnt 1 or new_items[0].webkitGetAsEntry().isDirectory
				@cb 'CANCEL_EMPTY', null, null, accept: @accept
				@_cancel()
				return false
		if new_items.length is 0
			@cb 'CANCEL_EMPTY', null, null, accept: @accept
			@_cancel()
			return false
		@handleFiles items
		return true

	handleFiles: (@top_items) ->
		f= 'E:Drop.handleFiles'
		_log2 f, @top_items.length, @top_items
		return if not @_Progress 'START'
		# Top-items are DirectoryTransferItems (need webkitGetAsEntry)
		for i in [0...@top_items.length]
			entry= @top_items[i].webkitGetAsEntry()
			_log3 f, 'TOP entry #', i, entry
			if entry.isDirectory
				@top_list.push entry
			else
				@counters.total_files+= 1
				do (entry) =>
					_log3 f, 'TOP entry.file'
					entry.file (file) => # The whole world has gone async!
						_log3 f, 'file', file, @
						@top_files.push file
						@counters.pending+= 1
						@counters.total_bytes+= file.size+ 1
					, (err) =>
						_log f, 'ERROR, entry.file()', err
						@counters.total_files-= 1
		@_Populate @top_list, @last_ix
		@_AddMoreDirs()
		# THIS RETURNS RIGHT AWAY, WHILE readEntries IS RUNNING STILL

	_AddMoreDirs: () ->
		f= 'E:Drop._AddMoreDirs'
		_log2 f, last_ix: @last_ix, fol: @final_dirs.length
		if @last_ix>= @final_dirs.length
			_log2 f, last_ix: @last_ix, f_len: @final.length, fo_len: @final_dirs.length, final: @final
			@_StepCountComplete()
			return
		start_ix= @last_ix
		@last_ix= @final_dirs.length
		for ix in [start_ix...@last_ix]
			last_entry= ix is @last_ix- 1
			do (ix,last_entry) =>
				@final_dirs[ix].createReader().readEntries (list) =>
					@_Populate list, ix+ 1
					@_AddMoreDirs() if last_entry
					return
		return

	_Populate: (list, ix) ->
		f= 'E:Drop._Populate'
		_log2 f, len: list.length, ix: ix
		@_Progress 'COUNT_ENTRIES', 'ASYNC'
		file_list= []
		@final_files[ix- 1]= file_list # ix:0 was trimmed of files earlier; Expect to push to file-list asnyc-ly
		for i in [0...list.length]
			entry= list[i]
			if entry.isDirectory
				@final.push ix: ix, name: entry.name
				@final_dirs.push entry
				@counters.total_folders+= 1
			else
				@counters.total_files+= 1
				do (entry,file_list) =>
					entry.file (file) => # The whole world has gone async!
						_log3 f, 'inside file', @, @counters
						file_list.push file
						@counters.pending+= 1
						@counters.total_bytes+= file.size+ 1
					, (err) => # TODO DOES .file() HAVE THIS ERR FUNC IN IT'S API? WAS .getMetadata()
						_log f, 'ERROR, entry.file', err
						@counters.total_files-= 1
		return

	_StepCountComplete: (trys) ->
		f= 'E:Drop._StepCountComplete'
		_log2 f, trys
		if not @step_count_progress_called
			@step_count_progress_called= true
			return if not @_Progress 'COUNT_BYTES'
		# Wait for all the sizes to be added up
		trys= if trys then trys+ 1 else 1
		if trys> 10
			alert "Unable to 'stat' file sizes. (#{@counters.pending}/#{@counters.total_files})"
			@cb 'CANCEL_ABORT'
			@_cancel()
			return
		if @counters.total_files > @counters.pending
			return setTimeout (=> @_StepCountComplete trys if not @cancel), 500
		@_StepConfirm()

	_StepConfirm: (after) -> # Do explicit confrim now that we know the size of everyrthing
		return setTimeout (=> @_StepConfirm true if not @cancel), 150 if not after
		if @counters.total_folders+ @counters.total_files is 0
			@cb 'CANCEL_EMPTY', null, null, accept: @accept
			@_cancel()
			return
		return if not @_Progress 'CONFIRM'

	_StepUploadFolders: (confirm) =>
		f= 'E:Drop._StepUploadFolders'
		return if @step_upload_folders_called
		@step_upload_folders_called= true
		return if not confirm
		return if not @_Progress 'UPLOAD_FOLDERS'
		return @_StepUploadFiles() if @counters.total_folders is 0
		response= @rest.post 'Project/'+ @prid+ '/Folder/'+ @parent_foid+ '/folders', f,
			folder_list: JSON.stringify @final
		_log2 f, response
		if not response.folder_ids
			@cb 'RESPONSE', @counters, true, subevent: 'FOLDERS_ERROR', response: response
			@cb 'CANCEL_ABORT'
			@_cancel(); return

		@folder_ids= response.folder_ids
		@counters.folders= @counters.total_folders # We're done with folders
		keep_going= @cb 'RESPONSE', @counters, true,
			subevent: 'FOLDERS', parent_foid: @parent_foid, response: response, folders_info: @final
		( @_cancel(); return ) if not keep_going
		@_StepUploadFiles()

	_StepUploadFiles: () ->
		f= 'E:Drop._StepUploadFiles'
		_log f, @top_files, fol: @final_dirs, fil: @folder_ids.length
		return if not @_Progress 'UPLOAD_FILES'
		# To top level files, that go into pre-existing parent_foid folder
		for file in @top_files
			@_UploadFile @parent_foid, file
		return @_StepWhileUploadFiles() if @folder_ids.length is 0 #@counters.total_folders is 0
		@_StepUploadFilesNotTop()

	_StepUploadFilesNotTop: () ->
		for i in [0...@folder_ids.length] # Use 'i' for folder_ids and final_files
			parent_id= @folder_ids[i]
			for file in @final_files[i]
				@_UploadFile parent_id, file
		# Give quarter second updates
		@_StepWhileUploadFiles()

	_UploadFile: (parent_id, file) ->
		return if @cancel
		if @uploads_active> 2
			@uploads_todo_list.push [parent_id, file]
			return
		handle= 'xhr_upload_file_'+ @_unique()
		f= 'E:Drop._UploadFile:'+ handle
		@uploads_active+= 1
		reported_bytes= 0
		@uploads_xhr[handle]= @rest.upload_file @prid, parent_id, file, @drop_type, (event,p1,p2) =>
			# event: start, progress(sofar,total), success(result), fail(err)
			#_log3 f, event, file.name, p1: p1, p2: p2
			return if @cancel
			done= false
			switch event
				when 'start'
					@cb 'ONE_FILE', @counters, false,
						subevent: 'START', handle: handle, file: file, parent_id: parent_id, sofar: 0, total: file.size, as_percent: '0%'
				when 'fail'
					@cb 'RESPONSE', @counters, true,
						subevent: 'FILE_ERROR', handle: handle, file: file, parent_id: parent_id, response: p1
					done= true
				when 'success'
					@cb 'RESPONSE', @counters, true,
						subevent: 'FILE', handle: handle, file: file, parent_id: parent_id, response: p1
					done= true
				when 'progress'
					bytes= p1- reported_bytes
					@counters.bytes+= bytes
					reported_bytes+= bytes
					perc= Math.floor((p1/p2)*100) + '%'
					@counters.total_percent= Math.floor((@counters.bytes/@counters.total_bytes)*100) + '%'
					@cb 'ONE_FILE', @counters, false,
						subevent: 'PROGRESS', handle: handle, file: file, parent_id: parent_id, sofar: p1, total: p2, as_percent: perc
			if done
				delete @uploads_xhr[handle]
				@uploads_active-= 1
				@counters.files+= 1
				@counters.bytes+= file.size+ 1- reported_bytes
				@counters.total_percent= Math.floor((@counters.bytes/@counters.total_bytes)*100) + '%'
				@cb 'ONE_FILE', @counters, true,
					subevent: 'END', handle: handle, file: file, parent_id: parent_id, sofar: file.size, total: file.size, as_percent: '100%'
				@_StepFinish() if @counters.files is @counters.total_files
				if @uploads_todo_list.length
					[todo_parent_id, todo_file]= @uploads_todo_list.shift 0
					@_UploadFile todo_parent_id, todo_file

	_StepWhileUploadFiles: (again) =>
		# Case where there are not files (_UploadFile won't get to do 'finish')
		return @_StepFinish() if @counters.total_files is 0
		# Give periodic updates
		if @counters.files < @counters.total_files
			@_Progress 'UPLOAD_FILES'
			setTimeout (=> @_StepWhileUploadFiles again if not @cancel), 500

	_StepFinish: (after) ->
		return setTimeout (=> @_StepFinish true if not @cancel), 10 if not after
		return if not @_Progress 'FINISH' # Caller must return false, to avoid my default 'alert'
		msg= '(DEFAULT MESSAGE) Uploaded '
		msg+=
			if @counters.total_folders
				"#{@counters.folders} of #{@counters.total_folders} folders "
			else ''
		msg+=
			if @counters.total_files
				"#{@counters.files} of #{@counters.total_files} files " +
				"totaling #{@counters.bytes} of #{@counters.total_bytes} bytes"
			else ''
		msg+= '!'
		alert msg
		#TODO CONFIRM THAT THIS IS CAUSING PROBLEMS WITH SENDING SAME FILES A SECOND TIME @_reset()

	_Progress: (step_name, subevent, data) ->
		f= 'E:Drop._Progress:'+ step_name
		#_log3 f, step_name, @step, @step_types[@step]
		# Call user's progress callback, with 'true' as last call for this step

		step= @step_types.indexOf (if step_name is 'CONFIRM' then @step_before_confirm else step_name)
		alert f+ ' Unknown step_name' if step is -1 # TODO REMOVE DEBUG
		new_step= @step< step
		while @step< step
			if not @cb @step_types[@step], @counters, true # Make 'last' steps
				@_cancel(); return false
			@step+= 1
		# Call user's progress callback to 'start'/'continue' next step
		if step_name is 'CONFIRM'
			@cb 'CONFIRM', @counters, true, @_StepUploadFolders
			return true # They'll get back to us, later
		if not @cb @step_types[@step], @counters, false
			@_cancel(); return false
		#_log3 f, 'good'
		return true

window.EpicMvc.Extras.Drop= Drop # Public API

class ProgressSample2
	constructor: (@loader,@project_id) ->
		@stopped= false
		@model_folders= window.EpicMvc.Epic.getInstance 'Directory'
		@model_uploads= window.EpicMvc.Epic.getInstance 'Uploads'
		@model_id= @model_uploads.newUpload @, @project_id
		@did_confirm= false
	Cancel: -> # User proactive cancel, don't call makeClick
		@loader.Cancel()
		@stopped= true
	_stop: (msg,no_click) ->
		return if @stopped
		@stopped= true
		alert msg if msg
		window.EpicMvc.Epic.makeClick false, 'cancel_progress', {id: @model_id}, true if no_click isnt true
		@model_uploads.uploadAbort @model_id
		return false

	progress: (step, cnt, last_flag, extra_data) =>
		f= 'E:ProgressSample2.progress'
		if step isnt "UPLOAD_FILES" and step isnt "ONE_FILE"
			_log2 f, step, last: last_flag, did: @did_confirm, extra_data: extra_data
		switch step
			when 'START'
				if last_flag
					@model_uploads.uploadProgress @model_id, cnt
					@stopped= false
			when 'CANCEL', 'CANCEL_ABORT'
				return @_stop step
			when 'CANCEL_EMPTY'
				if extra_data.accept?.length
					msg= 'No files found of type: '+ extra_data.accept.join '/'
				else
					msg= 'No files or folders found.'
				return @_stop msg, (if @did_confirm then false else true)
			when 'RESPONSE'
				if extra_data.subevent is 'FOLDERS_ERROR'
					return @_stop 'Error on server, uploading folder structure.'
				else if extra_data.subevent is 'FOLDERS'
					@model_folders.foldersUploaded @model_id, @project_id,
						extra_data.parent_foid, extra_data.response.folder_ids, extra_data.folders_info
				else if extra_data.subevent is 'FILE' or extra_data.subevent is 'FILE_ERROR'
					@model_uploads.fileResponse @model_id, extra_data.handle, $.extend {}, extra_data.response
					@model_folders.fileResponse @model_id, extra_data.handle, $.extend {}, extra_data.response
			when 'CONFIRM'
				return true if @did_confirm # Sometimes called twice in a row
				@did_confirm= true
				stats= $.extend {}, cnt, step: step, last: (if last_flag then 'yes' else '')
				@model_uploads.uploadProgress @model_id, stats
				@model_uploads.replyCallback  @model_id, extra_data
				if false # TODO MOVE THIS LOGIC TO THE MODEL
					ff_limit= 20000
					fol_limit= 500
					msg= []
					if cnt.total_files+ cnt.total_folders> ff_limit
						msg.push "#{ff_limit} files+folders"
					if cnt.total_folders> fol_limit
						msg.push "#{fol_limit} folders"
					if msg.length
						return @_stop "Exceded max of "+ (msg.join 'and')+
							" [Folder count: #{cnt.total_folders}] [File count: #{cnt.total_files}]"

					answer= @_confirm cnt
					return true if answer # TODO 'yes' if answer # Require to be expicitly the 'yes' string
					return @_stop()
				return true # Wait on the model to call back into the Drop instance
		switch step
			when 'ONE_FILE'
				@model_uploads.fileProgress @model_id, extra_data.handle, $.extend {}, extra_data, name: extra_data.file.name
				@model_folders.fileProgress @model_id, extra_data.handle, $.extend {}, extra_data, name: extra_data.file.name, project_id: @project_id
			else
				if step is 'FINISH' or step.match /^(UPLOAD|COUNT)_/
					stats= $.extend {}, cnt, step: step, last: (if last_flag then 'yes' else '')
					@model_uploads.uploadProgress @model_id, stats

		return step isnt 'FINISH' # false to avoid built-in finish alert

	_confirm: (cnt) ->
		question = 'Upload '
		question+=( if cnt.total_folders then "#{cnt.total_folders} folders " else '')
		question+=
			if cnt.total_files
			then "#{cnt.total_files} files, total #{cnt.total_bytes} bytes"
			else ''
		question+='?'
		return confirm question

window.EpicMvc.Extras.ProgressSample2= ProgressSample2 # Public API
