
window.EpicMvc.app$iBeacon=
	OPTIONS:
		frame: DDD_iBeacon: 'ibeacon_frame1', QQQ_iPM: 'whatever'
		# login:	flow: 'ibeacon'
	MODELS:
		Directory:	class: 'FolderExt'
	CLICKS:
		ibeacon: call: 'Pageflow/path', p:{path:'ibeacon/top/top'}
		ipm: call: 'Pageflow/path', p:{path:'home'}
	FLOWS:
		anon:
			v:{no_derek_stuff:''}
		home:
			v:{no_derek_stuff:''}
		ibeacon:
			CLICKS:
				browser_hash: call: "External/parse_hash", use_fields: 'hash'
			start: 'top'
			template: 'ibeacon'
			v:{scroll:'dummy',is_welcome:'',is_features:'',is_support:'',is_pricing:'',is_company:'',is_signin:'',is_register:''}
			TRACKS:
				top:
					start: 'top'
					v:{no_derek_stuff:'x'}
					STEPS:
						top: page: 'top'
					CLICKS:
						select_folder:	call: 'Directory/choose_folder_view', use_fields: 'id', RESULTS: [
							{ r:{}, call: 'Directory/load_floorplan', use_fields:'id'}
						]
						toggle_beacon_region: call: 'Directory/toggle_beacon_region', use_fields: 'id'
						go_open_s3_file: call: 'Directory/get_file_url', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'},	call: 'Pageflow/path', p:{path:'//open_s3_file'}
						]
						toggle_menu: call: 'Directory/toggle_menu'