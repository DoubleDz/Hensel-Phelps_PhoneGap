class FolderExt extends window.EpicMvc.Model.Folder
	constructor: (Epic,view_nm) ->
		ss=
			graphic_url: false,
		super Epic, view_nm, ss
		@inRegion= {}
		@beaconFolders= false
		@beaconfiles= []
		@bodyEl= document.body;
		@isOpen= false
		@isAnimating= false
	action: (act,p) ->
		f= "M:Folder.action(#{act})"
		_log2 f, p, ({}[n]=@[n] for n of @ss)
		r= {}
		i= new window.EpicMvc.Issue @Epic, @view_nm, act
		m= new window.EpicMvc.Issue @Epic, @view_nm, act
		switch act
			when 'toggle_menu'
				morphEl= document.getElementById 'morph-shape'
				s= Snap morphEl.querySelector 'svg'
				path= s.select 'path'
				initialPath= path.attr 'd'
				pathOpen= morphEl.getAttribute 'data-morph-open'
				_log2 morphEl, s, initialPath, pathOpen, @isAnimating
				return false if @isAnimating
				@isAnimating= true
				if @isOpen
					classie.remove @bodyEl, 'show-menu'
					# animate path
					setTimeout (=>
					# reset path
						path.attr 'd', initialPath
						@isAnimating= false
					), 300
				else
					classie.add @bodyEl, 'show-menu'
					# animate path
					path.animate {'path': pathOpen}, 400, mina.easeinout, =>
					    @isAnimating= false
				@isOpen= !@isOpen
			when 'toggle_beacon_region' #get becaon region files with p.id
				if @inRegion[p.id] is true
					@inRegion[p.id]= false
					for bfile in @beaconfiles
						if bfile.folder_id is (Number p.id)
							idx= @beaconfiles.indexOf(file)
							@beaconfiles.splice(idx,1)
				else
					@inRegion[p.id]= true
					for id, file of @c_files
						if file.folder_id is (Number p.id)
							@beaconfiles.push file
				_log2 'IN Region:', @inRegion[p.id], @beaconfiles;
				@invalidateTables true
			when 'load_floorplan' #load floorplan from p.id
				@beaconfolders= @c_folders
				for id, file of @c_files
					if file.folder_id is @folder_view_id[@project_active] and file.name is 'floorplan.png'
							response= @rest.get "/Project/#{@project_active}/File/#{file.id}/inline", 'S3Open()'
							if not ('signed_url' of response)
								alert 'S3Open() bad response: '+ JSON.stringify response
								return false
							else
								@file_signed_url= response.signed_url
								@Table= {}
								r.success= 'SUCCESS'
							@invalidateTables true
			else return super act, p
		[r, i, m]
	loadTable: (tbl_nm) ->
		f= 'M:FolderExt.loadTable:'+tbl_nm
		#_log2 f
		@_getProjectData()
		switch tbl_nm
			when 'BeaconInfo' # beacon info including svg
				table= []
				_log2 'FOLDERS', @c_folders
				for folder_id, folder of @c_folders
					beaconDict= {}
					beaconKeys= folder.name.split ", "
					beaconDict['folder_id']= folder.folder_id
					beaconDict['id']= folder.id
					for beacondata in beaconKeys
						parsedData= beacondata.split ":"
						beaconDict[parsedData[0]]= parsedData[1] 
					if beaconDict.id and beaconDict.folder_id and beaconDict.Beacon and beaconDict.UUID
						if folder.folder_id is @folder_view_id[@project_active]
							table.push beaconDict
				_log2 'BeaconInfo Table', table
				@Table[tbl_nm]= table
			# when 'Folder'
			# 	table= []
			# 	for folder_id, folder of @_getFolderTable @folder_view_id[@project_active]
			# 		type= folder.name.split ":", 1
			# 		table.push folder unless type[0] is 'Beacon'

			# 	@Table[tbl_nm]= table
			when 'RootFile'
				table= []
				if @root_open['PUBLIC']
					table= @_getFileTable @c_folders['PUBLIC'].id
				@Table[tbl_nm]= table
			when 'BeaconFile' # beacon info including svg
				table= []
				for file_id, file of @_getFileTable @folder_view_id[@project_active]
					file['icon_ext']= file.name.split ".", 2
					table.push file unless file.name is 'floorplan.png'
				if @beaconfiles.length > 0
					for beaconfile in @beaconfiles
						beaconfile.has_error= false
						beaconfile['icon_ext']= beaconfile.name.split ".", 2
						table.push beaconfile
				_log2 'FILE TABLE', table
				@Table[tbl_nm]= table
			else super tbl_nm
		return
	
		@cache?.GetProjectList() ? {}

window.EpicMvc.Model.FolderExt= FolderExt # Public API