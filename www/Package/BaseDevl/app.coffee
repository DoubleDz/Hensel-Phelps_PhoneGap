window.EpicMvc.app$BaseDevl=
	OPTIONS: frame: MMM_BaseDevl: 'bdevl'
	MODELS:
		Tag:      class: "TagExe$BaseDevl",     inst: "bdT"
		Devl:     class: "Devl$BaseDevl",       inst: "bdD"
	CLICKS:
		dbg_toggle:  call: 'Devl/toggle', use_fields: 'what'
		dbg_refresh: call: 'Devl/clear_cache'

