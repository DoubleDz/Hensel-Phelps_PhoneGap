window.EpicMvc.app$Base=
	OPTIONS:
		login: flow: "starter_flow$Base"
		template: default: "starter"
	MODELS:
		Pageflow: class: "Pageflow$Base",   inst: "bP"
		Security: class: "NoSecurity$Base", inst: "bS"
		Property: class: "Property$Base",   inst: "bPr"
		Tag:      class: "TagExe$Base",     inst: "bT"
	FLOWS:
		starter_flow$Base:
			start: "starter_track"
			TRACKS:
				starter_track:
					start: "starter_step"
					STEPS:
						starter_step: page: "page"

