#_log2= -> # TODO 2 REMOVE THIS
#_log3= window.Function.prototype.bind.call window.console.log, window.console # TODO 3 REMOVE THIS AND ANY _log3 BELOW
# Zip creation of a folder or whole project; invoked by Model/Downloads.coffee
# WARNING: Be careful that blob references do not persist (even in console.log msgs)
# 

class Zip
	constructor: (@prid, @parent_foid) -> # Parent_foid==0 means whole project
		f= 'E:Zip.constructor'
		_log f, 'prid/parent_foid', @prid, @parent_foid
		@zu= window.EpicMvc.Extras.ZipUtil
		@rest= window.EpicMvc.Extras.Rest
		@cancel= false
		@step_types= ['START', 'DOWNLOAD_FILES', 'ASSEMBLE', 'FINISH' ]
		@step= 0
		@counters= total_files: 0, total_bytes: 1, folders: 0, files: 0, bytes: 0, pending: 0
		@file_list= [] # {path:,name:,md5:,modified:}
		@folder_list= [] # {path:,modified:}
		@xfers_allow_active= 3
		@xfers_active= 0
		@xfers_todo_list= []
		@xfers_xhr= {}
		@xfers_complete= {} # hash by md5, false if not actually complete yet
		@crc_todo= []
		@zipname= 'somename.zip'
		@blob_size= 1* 1024* 1024
	_Cancel: (reason) ->
		alert reason if reason
		return if @cancel is true
		@cancel= true
		@cbo.Cancel()
		@cb= ->
		xhr.abort() for ix,xhr of @xfers_xhr
		return
	_Unique: () -> window.EpicMvc.Epic.nextCounter()
	_DoList: (list, cb_each_e, cbe_final) => # cb_each_e(item,cbe)
		offset= -1
		doOneE= (err) =>
			offset++
			if err isnt null or offset>= list.length then cbe_final err
			else cb_each_e list[offset], doOneE
		doOneE null
	_DoWhile: (cb_while_e, cbe_final) => # cb_while_e(cbe) (calls 'cbe' w/true/false to indicate continue/break)
		doOneE= (err,again) =>
			if err isnt null or not again then cbe_final err
			else cb_while_e doOneE
		doOneE null, true

	Cancel: -> @_Cancel()
	Start: (files, folders,project_name, @cbo, @download_dir, @active_download_dirs, download_prefix, include_versions) ->
		# Params: files (file_id:{md5,folder_id,name}, folders_id:{id,name} @cbo: (progress callback object)
		f= 'E:Zip.Start'
		_log f, 'files[0]/folders[0]/@prid/@parent_foid', files[0], folders[0], @prid, @parent_foid
		@prefix_pat= new RegExp "^#{download_prefix}.*"
		@cb= @cbo.progress
		@old_cb= @cb
		return if not @_Progress 'START'
		@zipname= (if @parent_foid is 0 then project_name else folders[@parent_foid].name)+ '.zip'
		@zipname= @zipname.replace /[\/:*?"><|\\]/, '-'
		@include_versions = include_versions
		# Snapshot file/folder data needed for downloading and zip creation
		@_snapFileFolder files, folders # Populates @file_list and @folder_list

		@counters.total_files= @counters.pending= @file_list.length
		(@counters.total_bytes+= rec.size) for ix,rec of @file_list
		@_StepPrepareTempFs @_StepXferFiles

	_snapFileFolder: (files,folders) ->
		f= 'E:Zip._snapFileFolder'
		# Create parent:[child...]
		child_folders= {}
		for id,rec of folders when id > 0 # Weed out fake 0 record, also PUBLIC/PRIVATE/FORMS string ids
			child_folders[rec.folder_id]?= []
			child_folders[rec.folder_id].push id
		_log f, 'child_folders', child_folders
		child_files= {}
		for id,rec of files
			continue if rec.type is 1 and not (rec.file_id of files) # Ignore annot's w/o parents
			child_files[rec.folder_id]?= []
			child_files[rec.folder_id].push id
		addFiles= (foid, parent_path) =>
			path= parent_path+ folders[foid].name+ '/'
			@folder_list.push path: path, modified: folders[foid].modified
			if foid of child_files
				for id in child_files[foid]
					rec= files[id]
					content_file= if rec.type is 0 then rec else files[rec.file_id]
					content_filename= content_file.name
					# Simulate a version path if needed
					version_path= ''
					if @include_versions and not content_file.latest
						v_ix= content_file.v_ix + ''
						version_path= content_file.name+ ' - versions/'
						content_filename= '00'.substring(0, 2 - v_ix.length) + v_ix + '-' + content_file.version_name
					# Simulate an annotation path if needed
					annot_path= if rec.type is 0 then '' else content_filename+ ' - annotations/'
					rec_name = if rec.type is 0 then content_filename else rec.name
					@file_list.push md5: rec.md5, path: path+ version_path+ annot_path, name: rec_name, size: (Number rec.size), id: id, modified: rec.modified
			if foid of child_folders
				(addFiles id, path) for id in child_folders[foid]
		addFiles @parent_foid, ''

	_StepPrepareTempFs: (cb) => # Open TempFs; Clean up disk; check for space; start a dir; open zipfile for writing
		f= 'E:Zip._StepPrepareTempFs'
		_log f
		@tempFs= false
		@tempFsRootDir= false
		@tempFsDirEntry= false
		@tempFsZipEntry= false
		@tempFsZipWriter= false

		IsErr= (err, who) =>
			_log2 'IsErr', who, err
			return false if err is null
			_log2 who, 'ERROR', err
			extra= if err.name is 'SecurityError' then 'Are you in Incognito mode?' else err.message
			@_Cancel "'Prepare Filesystem' error. (#{extra})"
			return true # Yes there was an error

		GetFs= (cbe) =>
			ff= f+':GetFsE'
			webkitRequestFileSystem TEMPORARY ,0 # No bytes requested yet, till we can clean out old dirs
				,(fs) =>
					_log2 ff, 'got fs', fs
					@tempFs= fs
					cbe null
				,(err) => cbe err
			return

		FsGetRootDir= (cbe) =>
			ff= f+':FsGetRootDir'
			_log2 ff
			@tempFsRootDir= @tempFs.root.createReader()
			_log2 ff, 'got rootDir', @tempFsRootDir
			cbe null
			return

		old_dirs= []
		FsReadDirs= (cbe) => # Used in _DoWhile, so pass along true/false
			ff= f+':FsReadDirs'
			_log2 ff
			@tempFsRootDir.readEntries(
				(entries) =>
					_log2 ff, 'got readEntries', entries
					if entries.length > 0
						for dir in entries
							if (@prefix_pat.test dir.name) and (@active_download_dirs.indexOf dir.name) is -1
								old_dirs.push dir
						cbe null, true
					else cbe null, false
				,(err) => cbe err)
			return

		FsRmDir= (dir,cbe) =>
			ff= f+':FsRmDir'
			_log2 ff, dir
			dir.removeRecursively (=> cbe null), (err) => cbe err
			return

		FsCheckSpace= (cbe) =>
			ff= f+':FsCheckSpace'
			_log2 ff
			navigator.webkitTemporaryStorage.queryUsageAndQuota(
				(used, remaining) =>
					need= @counters.total_bytes* 2+ (1* 1024* 1024)
					_log ff, 'used/remaining', used, remaining
					if remaining < need
						alert "Not enough space in the Temp Filesystem "+ # TODO 2 DO A REAL ERROR TO NOTIFY MODELS
							"(used=#{used}, remaining=#{remaining}, need=#{need}, short=#{need- remaining}"
						return cbe 'Not enough space.'
					cbe null
				,(err) => cbe err)
			return

		FsGetTempDir= (cbe) =>
			ff= f+':FsGetTempDir'
			_log2 ff
			@tempFs.root.getDirectory @download_dir ,create: true
				,(entry) =>
					_log2 ff, 'got dir entry', entry
					@tempFsDirEntry= entry
					cbe null
			,(err) => cbe err
			return

		FsGetZipWriter= (cbe) =>
			ff= f+':FsGetZipWriter'
			_log2 ff
			@tempFsDirEntry.getFile @zipname ,create: true
				,(entry) =>
					@tempFsZipEntry= entry
					entry.createWriter(
						(writer) =>
							_log2 ff, 'got writer', writer
							@tempFsZipWriter= writer
							cbe null
						,(err) => cbe err)
				,(err) => cbe err
			,(err) => cbe err
			return
		
		# Open tempFs; Clean up disk; check for space; start a dir; open zipfile for writing
		GetFs (err) => # Populates @tempFs
			return false if IsErr err, f
			FsGetRootDir (err) => # Populates @tempFsRootDir
				return false if IsErr err, f
				@_DoWhile FsReadDirs, (err) => # Populates old_dirs
					return false if IsErr err, f
					_log f, 'old_dirs', (rec.name for rec in old_dirs)
					@_DoList old_dirs, FsRmDir, (err) => # Remove each old_dir
						return false if IsErr err, f
						FsCheckSpace (err) => # check available space
							return false if IsErr err, f
							FsGetTempDir (err) =>
								return false if IsErr err, f
								FsGetZipWriter (err) => # Open the zipfile w/writer for ZipUtil
									return false if IsErr err, f
									cb()
									return
		
	_StepXferFiles: () =>
		f= 'E:Zip._StepXferFiles'
		return @_StepAfterXfer() if @file_list.length is 0
		@_xferFile rec for rec in @file_list
		# Give quarter second updates
		@_StepWhileXferFiles()

	_xferFile: (file_rec) ->
		entry= writer= false
		return if @cancel
		if @xfers_active>= @xfers_allow_active
			@xfers_todo_list.push [file_rec]
			return
		md5= file_rec.md5
		f= 'E:Zip._xferFile:'+ md5
		_log2 f
		# Avoid Xfer of the same md5 file
		reported_bytes= 0 # Supports DoneFile()
		DoneFile= (was_active,reason) => # Reason could be an error object
			#_log3 "3:df:#{if was_active then 'A' else 'D'},#{@xfers_active},#{md5}",reason # TODO 3
			if was_active
				if md5 not of @xfers_xhr
					@_Cancel 'Zip download issue #901-xhr' ; return false
				delete @xfers_xhr[md5]
				delete @xfers_complete[md5].blob # Free up this blob, since we did write it to disk by now
				delete @xfers_complete[md5].writer # Free up this writer, since we did write to disk by now
				delete @xfers_complete[md5] if reason isnt 'success' # User said to skip this one
				@xfers_active-= 1
			@counters.files+= 1
			@counters.bytes+= file_rec.size- reported_bytes
			@cb 'ONE_FILE', @counters, true,
				subevent: 'END', handle: md5, file: file_rec, sofar: file_rec.size, total: file_rec.size
			return @_StepAfterXfer() if @counters.files is @counters.total_files
			if @xfers_active< @xfers_allow_active
				if @xfers_todo_list.length
					[todo_file]= @xfers_todo_list.shift 0
					setTimeout (=> @_xferFile todo_file ), 0 # keep going

		if md5 of @xfers_complete
			DoneFile false, 'dup'
			return
		@xfers_complete[md5]= false
		@xfers_active+= 1

		FsGetFileWriter= (cbe) => # cbe(err,entry,writer)
			ff= f+':FsGetFileWriter'
			@tempFsDirEntry.getFile md5 ,create: true # TODO 2 COULD WE DETECT THAT IT ALREADY EXISTS ON DISK, OR SOMETHING?
				,(entry) =>
					entry.createWriter(
						(writer) =>
							_log2 ff, 'got file md5/entry/writer', md5, entry, writer
							cbe null, entry, writer
						,(err) => cbe err)
				,(err) => cbe err
			,(err) => cbe err

		FsWriteFile= (writer,blob,cbe) =>
			writer.onwriteend=    => cbe null
			writer.onerror= (err) => cbe err
			writer.write blob

		StartFile= (entry, writer, cb_md5) =>
			response= @rest.rest "/Project/#{@prid}/File/#{file_rec.id}/inline", f # TODO 2 SHOULD I WORRY THAT THIS IS SYCNRONOUS?
			if not ('signed_url' of response)
				@cb 'RESPONSE', @counters, true,
					subevent: 'FILE_ERROR', handle: md5, file: file_rec, response: response
				alert 'No signed_url '+md5 # TODO TRACK THAT AN ERROR HAS OCCURED ON A FILE TO BE DOWNLOADED
				cb_md5 md5
				return
			url= response.signed_url

			@xfers_xhr[md5]= @rest.download_file url, (event,p1,p2) =>
				# event: start, progress(sofar,total), success(result), fail(err)
				#_log3 f, event, file_rec.name, p1: p1, p2: p2
				return if @cancel
				done= false
				switch event
					when 'start'
						@cb 'ONE_FILE', @counters, false,
							subevent: 'START', handle: md5, file: file_rec, sofar: 0, total: file_rec.size
					when 'fail'
						@cb 'RESPONSE', @counters, true,
							subevent: 'FILE_ERROR', handle: md5, file: file_rec, response: p1
						done= true
					when 'success'
						@cb 'RESPONSE', @counters, true,
							subevent: 'FILE', handle: md5, file: file_rec, # NOTE: DON'T GIVE BLOB LEST CALLER PERSIST W/CONSOLE.LOG response: p1
						done= true
					when 'progress'
						bytes= p1- reported_bytes
						@counters.bytes+= bytes
						reported_bytes+= bytes
						@cb 'ONE_FILE', @counters, false,
							subevent: 'PROGRESS', handle: md5, file: file_rec, sofar: p1, total: p2
				if done
					@xfers_complete[md5]= blob: p1, start: 0, entry: entry, writer: writer
					cb_md5 md5, event is 'success'

		IsErr= (err, who) =>
			return false if err is null
			_log2 who, 'ERROR', err
			return true # Yes there was an error

		# Get writer for temp-file-system-entry; read file from network as blob; write blob to temp-fs-entry
		FsGetFileWriter (err,entry,writer) =>
			return false if IsErr err, f
			StartFile entry, writer, (md5,success) =>
				if not success
					DoneFile true, 'not success'
					return
				success= 'success'
				FsWriteFile writer, @xfers_complete[md5].blob, (err) =>
					if err isnt null
						_log f, 'FsWriteFile error', md5, err
						success= err
						#if not confirm 'Error with this one file; not sure of the name. Continue anyways?'
							#@_Cancel(); return
						alert 'An error has occured writing to local disk. Sorry.'
						@_Cancel(); return
						@cb 'WRITE_FS', @counters, true,
							subevent: 'FILE_ERROR', handle: md5, file: file_rec, response: err
					else # We will always eventually be called without an error object
						@cb 'WRITE_FS', @counters, true,
							subevent: 'FILE', handle: md5, file: file_rec, response: '(empty)'
						DoneFile true, success

	_StepWhileXferFiles: (again) =>
		# Give periodic updates
		if @counters.files < @counters.total_files
			@_Progress 'DOWNLOAD_FILES'
			setTimeout (=> @_StepWhileXferFiles again if not @cancel), 500

	_StepAfterXfer: () -> return @_StepCalcCrc32()
	_StepCalcCrc32: () ->
		@crc_todo=( md5 for md5 of @xfers_complete)
		@_doCrc() # Get started
	_doCrc: ->
		f= 'E:Zip._doCrc'
		_log2 f, 'todo', @crc_todo.length
		return @_StepAfterCalc32() if @crc_todo.length is 0
		rec= @xfers_complete[md5= @crc_todo.pop()]
		Blob2Crc32Async= (blob, prev_crc32, cbe) =>
			f2= 'E:Zip._doCrc.Blob2Crc32Async'
			_log2 f2, 'blob.size', blob.size
			reader= new FileReader()
			reader.onerror= (evt) =>
				_log2 f2, 'onerror', evt.target.error
				cbe evt.target.error
			reader.onload= (evt) =>
				_log2 f2, 'onload;result.length', evt.target.result.length
				data= new Uint8Array evt.target.result
				_log2 f2, 'onload;data.length', data.length
				cbe null, @zu.CalcCrc32 data, prev_crc32
				_log2 f2, 'BOTTOM-OF-ONLOAD'
			# Only do a slice at a time
			reader.readAsArrayBuffer blob
			_log2 f2, 'BOTTOM'
		FsGetFile= (entry,cbe) =>
			entry.file(
				(file) => cbe null, file
				,(err) => cbe err)
		IsErr= (err, who) =>
			return false if err is null
			_log2 who, 'ERROR', err
			return true # Yes there was an error

		FsGetFile rec.entry, (err,file) =>
			return false if IsErr err, f+'>FsGetFile'
			Blob2Crc32Async (file.slice rec.start, rec.start+ @blob_size), rec.crc32, (err, crc32) =>
				f3= 'E:Zip._doCrc(Blob2Crc32Async-CALLBACK)'
				_log2 f3, 'err/crc32', err, crc32
				alert err if err # TODO SOME ERROR PROCESSING ON BLOB READ ISSUE?
				rec.crc32= crc32
				rec.start+= @blob_size
				@crc_todo.push md5 if rec.start< file.size
				setTimeout (=> @_doCrc() if not @cancel), 0 # keep going
				_log2 f3, 'BOTTOM;crc32', crc32
		_log2 f, 'BOTTOM'

	_StepAfterCalc32: () -> return @_StepAssemble()
	_StepAssemble: -> # Now all md5's have: @xfers_complete[md5]= {entry:,crc32:}
		f= 'E:Zip._StepAssemble'
		files= []
		# ZipUtil.Assemble(files) return a blob; files={pathname:,entry:,crc32:,modified:Date}
		# Empty manifest file for now
		files.push pathname: 'MANIFEST.INF', modified: new Date(), size: 0 # Empty manifest file
		for rec in @folder_list
			files.push pathname: rec.path, size: 0, modified: new Date Date.parse rec.modified
		for rec in @file_list
			md5= @xfers_complete[ rec.md5]
			files.push pathname: rec.path+ rec.name, size: rec.size, entry: md5.entry, crc32: md5.crc32, modified: new Date Date.parse rec.modified
		@zu.Assemble @tempFsZipWriter, files, =>
			@tempFsZipEntry.file(
				(file) =>
					@final_blob= file
					@_StepFinish()
				(err) => _log2 f, err; alert 'TODO @tempFsZipEntry.file err')

	_StepFinish: (after) ->
		return setTimeout (=> @_StepFinish true if not @cancel), 10 if not after
		@counters.bytes+= 1 # Reserved one byte to get 100% even when 0 total_bytes
		return if not @_Progress 'FINISH', 'blob', blob: @final_blob, zipname: @zipname # Caller must return false, to avoid my default 'alert'
		msg= '(DEFAULT MESSAGE) Downloaded '
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

	_Progress: (step_name, subevent, data) ->
		f= 'E:Zip._Progress:'+ step_name
		#_log3 f, step_name, @step, @step_types[@step]
		# Call user's progress callback, with 'true' as last call for this step

		step= @step_types.indexOf step_name
		new_step= @step< step
		while @step< step
			if not @cb @step_types[@step], @counters, true # Make 'last' steps
				@_Cancel(); return false
			@step+= 1
		# Call user's progress callback to 'start'/'continue' next step
		if not @cb @step_types[@step], @counters, false, data
			@_Cancel(); return false
		#_log3 f, 'good'
		return true

window.EpicMvc.Extras.Zip= Zip # Public API

class ZipProgress
	constructor: (@loader,@project_id,@model_id) ->
		@stopped= false
		@model_xfer= window.EpicMvc.Epic.getInstance 'Downloads'
	Cancel: -> # User proactive cancel, don't call makeClick
		@loader.Cancel()
		@stopped= true
		@model_xfer._remove @model_id if @model_id # TODO CHANGE MODEL'S METHOD TO NOT HAVE _ NOW THAT WE CALL IT FROM OUTSIDE
		delete @model_id
	_stop: (msg) ->
		return if @stopped
		@stopped= true
		alert msg if msg
		window.EpicMvc.Epic.makeClick false, 'cancel_progress', {id: @model_id}, true
		return false

	progress: (step, cnt, last_flag, extra_data) =>
		f= 'E:ZipProgress.progress'
		_log2 f, step, last: last_flag, extra_data: extra_data if step isnt "DOWNLOAD_FILES" and step isnt "ONE_FILE"
		switch step
			when 'START'
				if last_flag
					@model_xfer.downloadProgress @model_id, cnt
					@stopped= false
			when 'CANCEL', 'CANCEL_ABORT'
				return @_stop step
			when 'RESPONSE'
				if extra_data.subevent is 'FILE' or extra_data.subevent is 'FILE_ERROR'
					@model_xfer.fileResponse @model_id, extra_data.handle, $.extend {}, extra_data.response
		switch step
			when 'ONE_FILE'
				@model_xfer.fileProgress @model_id, extra_data.handle, $.extend {}, extra_data, name: extra_data.file.name
			else
				if step is 'FINISH' or step.match /^(DOWNLOAD|COUNT)_/
					stats= $.extend {}, cnt, step: step, last: (if last_flag then 'yes' else '')
					@model_xfer.downloadProgress @model_id, stats

		if step is 'FINISH' and extra_data
			#alert 'Maybe put the auto-click in here, eh? extra_data.size='+ extra_data.size
			@do_click (window.URL.createObjectURL extra_data.blob), extra_data.zipname
		return step isnt 'FINISH' # false to avoid built-in finish alert


	do_click: (url,filename) ->
		# `url` can be a data URI like data: or a blob URI like blob: or an existing, public resource like http:
		# `filename` is the (default) name the file will be downloaded as

		link= document.createElement 'a'
		link.setAttribute 'href', url
		link.setAttribute 'download', filename
		event= document.createEvent 'MouseEvents'
		event.initMouseEvent 'click', true, true, window, 1, 0, 0, 0, 0, false, false, false, false, 0, null
		link.dispatchEvent event


window.EpicMvc.Extras.ZipProgress= ZipProgress # Public API
