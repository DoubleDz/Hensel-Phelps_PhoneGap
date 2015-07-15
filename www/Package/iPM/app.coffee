window.EpicMvc.app$iPM=
	OPTIONS:
		frame:		QQQ_iPM: 'ipm_frame_1'
		login:		flow: 'home'
		template:	default: 'LoggedOut', slide: 'modal', progress: 'modal', auth: 'modal'
		settings:	group: 'ipm', show_issues: 'inline'
	MODELS:
		External:	class: 'External',	inst: 'ipmEx'
		Admin:		class: 'Admin',		inst: 'ipmAd', forms: 'AdminUserEdit,AdminUserEditLevel'+
			',UserInviteForTeam,AdminSponsorAddEmail,AdminUserEditBankcheck,AdminEmailTest'
		User:		class: 'User',		inst: 'ipmUs', forms: 'Login,User'+
			',UserInviteOther,UserInviteTeam,UserInviteAdam,UserInviteAdamLtd,UserRegister,RequestInvite'+
			',ProfileEdit,ProfileExtended,UserForgot,UserForgotFinish,ChangePass,UserInviteProject,UserInviteProjectAdam'
		Directory:	class: 'Folder',	inst: 'ipmFo', forms: 'Folder,File,Project,TeamAddEmail,ProjectRename,Template,CloneProject,ComposeNotify'
		Uploads:	class: 'Uploads',	inst: 'ipmUp'
		Downloads:	class: 'Downloads',	inst: 'ipmDn'
		Sponsor:	class: 'Sponsor',	inst: 'ipmSp', forms: 'SponsorAddEmail,ModifyTeamUser,AddNewTeamUser'
		Billing:	class: 'Billing',	inst: 'ipmBi', forms: 'CardInfo,ProfileAddon'
	MACROS:
		start: call: 'User/check', p:{}, RESULTS: [
			{ r:{valid:'no'},    call: 'Pageflow/path', p:{path: 'anon/login'} }
			{ r:{loading:'yes'}, call: 'Pageflow/path', p:{path: 'home/main/loading'} }
			{ r:{projects:'no'}, call: 'Pageflow/path', p:{path: 'home'} }
			{ r:{},              call: 'Directory/default_first_project', RESULTS: [
				{ r:{},          call: 'Pageflow/path', p:{path: 'home'} }
			] }
		]
		invite: call: 'User/set_invite_code', use_fields: 'code', RESULTS: [
			{ r:{success: 'FAIL'}, call: 'Pageflow/path', p:{path: 'anon/login/signup'} }
			{ r:{}, call: 'Pageflow/path', p:{path: 'anon/login/invite'} }
		]
		forgot: call: 'User/set_forgot_code', use_fields: 'code', RESULTS: [
			{ r:{success: 'FAIL'}, call: 'Pageflow/path', p:{path: 'anon/login/'} }
			{ r:{}, call: 'Pageflow/path', p:{path: 'anon/login/forgot_return'} }
		]
		pre_reg_confirm: call: 'User/pre_reg_confirm_code', use_fields: 'code', RESULTS: [
			{ r:{}, call: 'Pageflow/path', p:{path: 'anon/login/'} }
		]
		confirm: call: 'User/confirm_code', use_fields: 'code', RESULTS: [
			{ r:{}, call: 'Pageflow/path', p:{path: 'anon/login/login'} }
		]
		close_modal: call:'Pageflow/restore_path' # TODO Determine who/how stat is popped
		close_progress: call:'Pageflow/restore_path', RESULTS: [ # TODO Determine who/how stat is popped
			r:{}, call: 'Uploads/close'
		]
		clear_landing:	call: 'Directory/choose_folder_edit', p:{id:false}, RESULTS: [
			r:{}, call: 'Directory/choose_file_edit',  p:{id:false}, RESULTS: [
				r:{}, call: 'Pageflow/path', p:{path:'//landing'}
			]
		]
		clear_profile:	call: 'Sponsor/add_sponsor_close', p:{id:false}, RESULTS: [
			r:{}, call: 'Pageflow/path', p:{path:'//profile'}
		]
		# Would like to put go_payment under that 'flow' but appconf only looks here for now
		go_payment: call: 'Billing/check_for_card', RESULTS: [
			{ r:{card: 'YES'}, go: '//payment' }
			{ r:{}, go: '//card_enter' }
		]
		go_billing_select: call: 'Billing/select_plan_default', go: 'myprofile/bill/select'
	CLICKS:
		'Security.rest1': # Initial attempt?
			call:'Pageflow/path', p:{path:'anon/login/login'}
		'Security.rest2': # Durring render?
			call:'Pageflow/save_path', RESULTS: [
				call:'Pageflow/path', p:{path:'anon/login/login_saved'}
			]
		browser_hash: call: "External/parse_hash", use_fields: "hash", RESULTS: [
			{ r:{page:'pre_reg'},	macro: 'pre_reg_confirm',	use_result: 'code' }
			{ r:{page:'welcome'},	call: 'Pageflow/path', p:{path: 'anon/login/home'} }
			{ r:{page:'features'},	call: 'Pageflow/path', p:{path: 'anon/login/home_features'} }
			{ r:{page:'support'},	call: 'Pageflow/path', p:{path: 'anon/login/home_support'} }
			{ r:{page:'pricing'},	call: 'Pageflow/path', p:{path: 'anon/login/home_pricing'} }
			{ r:{page:'plans'},		call: 'Pageflow/path', p:{path: 'anon/login/pricing_details'} }
			{ r:{page:'company'},	call: 'Pageflow/path', p:{path: 'anon/login/home_company'} }
			{ r:{page:'privacy'},	call: 'Pageflow/path', p:{path: 'anon/login/privacy_page'} }
			{ r:{page:'signup'},	call: 'Pageflow/path', p:{path: 'anon/login/signup'} }
			{ r:{page:'login'},		call: 'Pageflow/path', p:{path: 'anon/login/login'} }
			{ r:{page:'mobile'},	call: 'Pageflow/path', p:{path: 'anon/login/mobile'} }
			{ r:{page:'myoverview'}, go: 'myprofile/bill/overview' }
			{ r:{page:'terms'},		call: 'Pageflow/path', p:{path: 'anon/login/terms_page'} }
			{ r:{page:'signup_confirm'},	macro: 'invite',			use_result: 'code' }
			{ r:{page:'confirm'},			macro: 'confirm',			use_result: 'code' }
			{ r:{page:'forgot'},			macro: 'forgot',			use_result: 'code' }
			{ r:{page:'contact_us'}, call: "External/choose_learn_contact_us", RESULTS: [
				{ r: {}, call: 'Pageflow/path', p:{path:'anon/login/learn'}}
			]}
			{ r:{page:'invite'},  macro: 'invite', use_result: 'code' }
			{ r:{page:'team'},     call:'Directory/url_team_context', use_result: 'code:context', RESULTS: [
				{ r:{            },   call: 'Pageflow/path', p:{path: 'home/main/team_maint'} }
			] }
			{ r:{page:'folders'},  call:'Directory/url_landing_context', use_result: 'code:context', RESULTS: [
				{ r:{            },   macro: 'start' } # Standard landing page logic
			] }
			{ r:{            },   macro: 'start' } # Default
		]
		close_modal: macro: 'close_modal'
		close_progress: macro: 'close_progress'
		clear_login_msg: call: 'User/clear_login_msg'
		logout: call: 'User/logout', RESULTS: [
			r:{}, call:'Pageflow/path', p:{path:'anon/login/login'}
		]
		refresh: call: 'Pageflow/refresh'
		request_invite: call: 'User/request_invite', use_form: 'RequestInvite'
		resend_invite:  call: 'User/resend_invite', use_fields: 'id'
		go_admin:			call: 'Pageflow/path', p:{path:'admin/main'}
		go_admin_users:		call: 'Pageflow/path', p:{path:'admin/main/users'}
		go_admin_bankcheck:	call: 'Pageflow/path', p:{path:'admin/main/bankcheck'}
		go_admin_projects:	call: 'Pageflow/path', p:{path:'admin/main/projects'}
		go_admin_prereg:	call: 'Pageflow/path', p:{path:'admin/main/prereg'}
		go_admin_test:		go:'admin/main/test'
		go_admin_pstats:	go:'admin/main/pstats'
		go_home:			call: 'Pageflow/path', p:{path:'home/main/home'}
		go_privacy:			call:'Pageflow/save_path', RESULTS: [
			call:'Pageflow/path', p:{path:'anon/login/privacy'}
		]
		go_terms:			call: 'Pageflow/save_path', RESULTS: [
			call:'Pageflow/path', p:{path:'anon/login/terms'}
		]
		go_billing:  go: 'myprofile/bill/'
		go_billing_select: macro: 'go_billing_select'
		go_card_change: go: 'myprofile/bill/card_change'
		billing_upgrade_to: call: 'Billing/select_plan', use_fields: 'prefix', go: 'myprofile/bill/select'
	FLOWS:
		anon:
			start: 'login'
			v:{scroll:'dummy',is_welcome:'',is_features:'',is_support:'',is_pricing:'',is_company:'',is_signin:'',is_register:''}
			TRACKS:
				login:
					start: 'home'
					CLICKS:
						cancel: call: 'Pageflow/path', p:{path:'//login'}
						forgot: call: 'User/forgot_xfer', use_form: 'UserForgot', RESULTS: [ # Save off pswd already entered
							r:{}, call: 'Pageflow/path', p:{path:'//forgot'}
						]
						go_home:					call: 'Pageflow/path', p:{path:'//home_welcome'}
						go_home_features:			call: 'Pageflow/path', p:{path:'//home_features'}
						go_home_support:			call: 'Pageflow/path', p:{path:'//home_support'}
						go_home_pricing:			call: 'Pageflow/path', p:{path:'//home_pricing'}
						go_home_company:			call: 'Pageflow/path', p:{path:'//home_company'}
						go_signup:					call: 'Pageflow/path', p:{path:'//signup'}
						go_log_in:					call: 'Pageflow/path', p:{path:'//login'}
						go_mobile_apps:				call: 'Pageflow/path', p:{path:'//mobile'}
						go_support:					call: 'Pageflow/path', p:{path:'//support'}
						go_plans:					call: 'Pageflow/path', p:{path:'//pricing_details'}
					STEPS:
						login_saved:	page:'login', modal: 'auth', CLICKS:
							login:	call: 'User/login', use_form: 'Login', RESULTS: [
								{ r:{success:'SUCCESS'}, call: 'Pageflow/restore_path' }
							]
						home:			page: 'home', 	v:{scroll:'welcome',is_welcome:'yes'}, 		dom_cache:'welcome'
						home_features:	page: 'home', 	v:{scroll:'features',is_features:'yes'}, 	dom_cache:'features'
						home_support:	page: 'home', 	v:{scroll:'support',is_support:'yes'}, 		dom_cache:'support'
						home_pricing:	page: 'home', 	v:{scroll:'pricing',is_pricing:'yes'}, 		dom_cache:'pricing'
						home_company:	page: 'home', 	v:{scroll:'company',is_company:'yes'}, 		dom_cache:'company'
						privacy: page: 'privacy_policy', v:{is_welcome:'yes'}, modal: 'slide', dom_cache:'privacy', CLICKS:
							close_modal:	macro: 'close_modal'
							cancel:			macro: 'close_modal'
						terms: page: 'terms_of_use', v:{is_welcome:'yes'}, modal: 'slide', dom_cache:'terms', CLICKS:
							close_modal:	macro: 'close_modal'
							cancel:			macro: 'close_modal'
						privacy_page: 		page: 'privacy_policy', v:{is_welcome:'yes'}, dom_cache:'privacy'
						terms_page: 		page: 'terms_of_use', v:{is_welcome:'yes'}, dom_cache:'terms'
						signup:			page: 'signup', v:{is_register:'yes'}, dom_cache:'signup'
						login:			page: 'login', 	v:{is_signin:'yes'}, dom_cache:'login', CLICKS:
							login:	call: 'User/login', use_form: 'Login', RESULTS: [
								{ r:{success:'SUCCESS'}, macro: 'start' }
							]
						request_invite:	page:'invite_finish', v:{is_register:'yes'}, url: 'User/url_invite', CLICKS:
							save:	call: 'User/register', use_form: 'UserRegister', RESULTS: [
								{ r:{success:'CONFIRM'}, call: 'Pageflow/refresh' }
								{ r:{success:'SUCCESS'}, macro: 'start' }
							]
						invite:	page:'invite_finish', v:{is_register:'yes'}, url: 'User/url_invite', CLICKS:
							save:	call: 'User/register', use_form: 'UserRegister', RESULTS: [
								{ r:{success:'CONFIRM'}, call: 'Pageflow/refresh' }
								{ r:{success:'SUCCESS'}, macro: 'start' }
							]
						forgot:	page:'forgot_pswd', CLICKS:
							send:	call: 'User/send_forgot', use_form: 'UserForgot', RESULTS: [
								{ r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//login'} }
							]
						forgot_return:	page:'forgot_finish', CLICKS:
							save:	call: 'User/forgot_finish', use_form: 'UserForgotFinish', RESULTS: [
								{ r:{success:'SUCCESS'}, macro: 'start' }
							]
						mobile: page: 	'mobile_apps', v:{is_features:'yes'}
						support: page: 	'support', v:{is_support:'yes'}
						pricing_details:	page: 'pricing_plans', v:{scroll:'plans_top',is_pricing:'yes'}, dom_cache:'plans'
		home:
			start:		'main'
			template:	'vanilla'
			CLICKS:
				'Async.loaded': # The project-list was just now populated
					macro: 'start'
				'Async.reset_project': # The project a user was viewing is being reset
					macro: 'start'
				'Async.deleted_project': # The project a user was viewing has been deleted or user was removed
					macro: 'start'
				'Async.deleted_folder': # The folder-view a user had navigated to, was deleted
					macro: 'start'
				go_open_s3_file: call: 'Directory/get_file_url', use_fields: 'id', RESULTS: [
					r:{success:'SUCCESS'},	call: 'Pageflow/path', p:{path:'//open_s3_file'}
				]
				go_settings: call: 'Pageflow/path', p:{path:'//settings'}
				go_add_new_item: call: 'Directory/choose_upload_folder', use_fields: 'id:upload_folder', RESULTS: [
					r:{success:'SUCCESS'},	call: 'Pageflow/path', p:{path:'//add_new_item'}
				]
				toggle: call: 'Directory/toggle', use_fields: 'type,id'
				add_os_dialog: call: 'Directory/start_os_upload', use_fields: 'id,input_obj,callback_class', RESULTS: [
					{ r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/progress'} }
					{ r:{}, call: 'Pageflow/path', p:{path:'/main/'} }
				]
				go_profile:  call: 'Pageflow/path', p:{path:'myprofile'}
				go_history:  call: 'Pageflow/path', p:{path:'/main/history'}
				go_folders:  call: 'Pageflow/path', p:{path:'/main/landing'}
				go_new_user_email: call: 'User/have_email', use_fields:'email,project', RESULTS: [
					r:{}, call:'Pageflow/path', p:{path:'/main/user_add'}
				]
				go_new_user: call:'Pageflow/path', p:{path:'/main/user_add'}
				go_new_project: call: 'Pageflow/path', p:{path:'/main/project_add'}
				go_new_template: call: 'Pageflow/path', p:{path:'/main/template_add'}
				go_manage_team: call: 'Pageflow/path', p:{path:'/main/team_maint'}
				choose_project:	call: 'Directory/choose_project_view', use_fields: 'id'
				close_a_loader: call: 'Uploads/delete', use_fields: 'id'
				show_progress: call: 'Pageflow/save_path', RESULTS: [
					r:{}, call: 'Uploads/open', use_fields: 'id', RESULTS: [
						r:{}, call: 'Pageflow/path', p:{path:'/main/progress'}
					]
				]
				os_upload_drop: call: 'Directory/start_upload', use_fields: 'event,to,callback_class', RESULTS: [
					{ r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/progress'} }
					{ r:{}, call: 'Pageflow/path', p:{path:'/main/'} }
				]
				clip_remove_file:   call: 'Directory/remove_file_from_clip',   use_fields: 'id'
				clip_remove_folder: call: 'Directory/remove_folder_from_clip', use_fields: 'id'
				clip_remove_undofile:   call: 'Directory/remove_undofile_from_clip',   use_fields: 'id'
				clip_remove_undofolder: call: 'Directory/remove_undofolder_from_clip', use_fields: 'id'
				clip_clear:     call: 'Directory/clear_clip'
				folder_to_clip: call: 'Directory/folder_to_clip', use_fields: 'from'
				file_to_clip:   call: 'Directory/file_to_clip',   use_fields: 'from'
				move_file:      call: 'Directory/move_file',   use_fields: 'to,from'
				move_folder:    call: 'Directory/move_folder', use_fields: 'to,from'
				undo_file:      call: 'Directory/recover_file',   use_fields: 'id:from', RESULTS: [
					r:{ success: 'PARENT_DISPOSED'}, call: 'Directory/undofile_to_clip',   use_fields: 'id:from'
				]
				undo_folder:      call: 'Directory/recover_folder',   use_fields: 'id:from', RESULTS: [
					r:{ success: 'PARENT_DISPOSED'}, call: 'Directory/undofolder_to_clip',   use_fields: 'id:from'
				]
				recover_file_to:      call: 'Directory/recover_file_to',   use_fields: 'to,from'
				recover_folder_to:    call: 'Directory/recover_folder_to', use_fields: 'to,from'

				move_file_version:    call: 'Directory/move_file',         use_fields: 'to,from', p:{type:'version'}
				os_upload_drop_version:
					call: 'Directory/start_upload', use_fields: 'event,to,callback_class', p:{type:'version'}, RESULTS: [
						{ r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/progress'} }
						{ r:{}, call: 'Pageflow/path', p:{path:'/main/'} }
					]

				download_folder:call: 'Downloads/download', use_fields: 'id', p:{callback_class:'ZipProgress'}
				download_project:call: 'Downloads/download', p:{id:0, callback_class:'ZipProgress'}
				open_close:		call: 'Directory/open_close', use_fields: 'type,folder'
				choose_tab_profile:	call: 'Directory/choose_tab_profile', use_fields: 'tab', RESULTS: [
					r:{}, call: 'Pageflow/path', p:{path:'/main/profile'}
				]
				activate_version: call: 'Directory/activate_version', use_fields: 'id,current'
				delete_version: call: 'Directory/delete_version', use_fields: 'id,current'

			TRACKS:
				main: start:'landing', STEPS:

					landing: page: 'root', template: 'LoggedIn', url: 'Directory/url_landing', CLICKS:
						rename_file:			call: 'Directory/choose_file_edit', 	use_fields: 'id', 		RESULTS: false
						rename_folder:			call: 'Directory/choose_folder_edit', 	use_fields: 'id', 		RESULTS: false
						save_rename_file:		call: 'Directory/save_file', 			use_form: 'File'
						save_rename_folder:		call: 'Directory/save_folder', 			use_form: 'Folder'
						cancel_rename_file:		call: 'Pageflow/path', 					p:{path:'//landing'}, 	RESULTS: [
							r:{},   			call: 'Directory/choose_file_edit', 	p:{id:false}
						]
						cancel_rename_folder:	call: 'Pageflow/path', 					p:{path:'//landing'}, 	RESULTS: [
							r:{},   			call: 'Directory/choose_folder_edit', 	p:{id:false}
						]
						admin_stop_watching:	call: 'Directory/stop_watch_project', use_fields: 'id'
						filter_team_toggle:		call: 'Directory/filter_team_toggle'
						filter_activity_toggle:	call: 'Directory/filter_activity_toggle'
						filter_folder_toggle:	call: 'Directory/filter_folder_toggle'
						add_team_open:	call: 'Directory/add_team_open'
						add_team_close:	call: 'Directory/add_team_close'
						project_type:	call: 'Directory/project_type', use_fields: 'type'
						open_public:	call: 'Directory/open_close', p:{folder:'PUBLIC', type:'open'}
						close_public:	call: 'Directory/open_close', p:{folder:'PUBLIC', type:'close'}
						open_private:	call: 'Directory/open_close', p:{folder:'PRIVATE', type:'open'}
						close_private:	call: 'Directory/open_close', p:{folder:'PRIVATE', type:'close'}
						choose_folder:	call: 'Directory/choose_folder_view', use_fields: 'id'
						choose_folder_from_filter:	call: 'Directory/choose_folder_view', use_fields: 'id', RESULTS: [
							r:{}, call: 'Directory/filter_folder_close'
						]
						choose_project:			call: 'Directory/choose_project_view', 	use_fields:'id'
						set_as_member:			call: 'Directory/change_member', 		use_fields:'id', p:{as:'member'}
						set_as_manager:			call: 'Directory/change_member', 		use_fields:'id', p:{as:'manager'}
						set_as_owner:			call: 'Directory/change_member', 		use_fields:'id', p:{as:'owner'}
						ping_manager:			call: 'Directory/ping_member',			use_fields:'id,as'
						remove_member:	call: 'Directory/remove_member', use_fields:'id'
						delete_folder:	call: 'Directory/choose_folder_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//delete'}
						]
						delete_file:	call: 'Directory/choose_file_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//delete_file'}
						]
						add_folder: call: 'Directory/choose_upload_folder', use_fields: 'upload_folder', RESULTS: [
							r:{success:'SUCCESS'},	call: 'Pageflow/path', p:{path:'//add'}
						]
						add_file: call: 'Directory/choose_upload_folder', use_fields: 'upload_folder', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//add_file'}
						]
						choose_permission: call: 'Directory/choose_permission', use_fields: 'id,folder,perm,descend'
						add_team_email:	call: 'Directory/add_member', use_form: "TeamAddEmail", p:{as:'member'}, RESULTS: [
							{r:{success:'SUCCESS'}, call: 'Directory/add_team_close'}
							{r:{success:'NO_SUCH_USER'}, call: 'User/have_email', use_fields: 'TeamEmail:email' }
						]
						invite_project_team_add:	call: 'User/invite_team_project', use_form: "UserInviteProject", use_fields: 'project_id', RESULTS: [
							{r:{success:'SUCCESS'}, call: 'Directory/add_team_close'}
						]
						delete_project:	call: 'Directory/choose_project_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//project_delete'}
						]
						clone_project:	call: 'Directory/choose_project_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//project_clone'}
						]
						rename_project:	call: 'Directory/choose_project_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//project_rename'}
						]
						close_a_download:	call: 'Downloads/delete', use_fields: 'id'
						abort_a_download:	call: 'Downloads/choose_loader', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//download_abort'}
						]
						project_notify: go: '//compose_notify'
					compose_notify: page: 'compose_notify', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						send:			call: 'Directory/notify_send', use_fields: 'user_list', use_form: 'ComposeNotify', RESULTS: [
							r:{success:'SUCCESS'}, go: '//landing'
						]
					settings: page: "settings"
					open_s3_file: 	page: 's3_view', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
					add_new_item: page: "add_new_items", modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						save_folder_name:		call: 'Directory/add_folder', use_form: 'Folder', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					loading:	page:'loading', CLICKS:
						'Async.loaded': macro: 'start'
					no_projects:	page:'no_projects'
					history:	page:'history'
					rename:		page:'folder_rename', CLICKS:
						cancel:		call: 'Pageflow/path', p:{path:'//landing'}
						save:		call: 'Directory/save_folder', use_form: 'Folder', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					rename_file:	page:'file_rename', CLICKS:
						cancel:		call: 'Pageflow/path', p:{path:'//landing'}
						save:		call: 'Directory/save_file', use_form: 'File', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					delete:		page:'folder_delete', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						save:		call: 'Directory/delete_folder', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Directory/toggle', p:{type:false}, RESULTS: [
								r:{}, macro: 'clear_landing'
							]
						]
					delete_file:	page:'file_delete', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						save:		call: 'Directory/delete_file', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Directory/toggle', p:{type:false}, RESULTS: [
								r:{}, macro: 'clear_landing'
							]
						]
					add:		page:'folder_add', CLICKS:
						cancel:		call: 'Pageflow/path', p:{path:'//landing'}
						save:		call: 'Directory/add_folder', use_form: 'Folder', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					add_file:	page:'file_add', CLICKS:
						cancel:		call: 'Pageflow/path', p:{path:'//landing'}
						save:		call: 'Directory/add_file', use_form: 'File', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					user_add:	page:'user_invite', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						create:		call: 'User/invite', use_form: 'UserInviteOther'
						create_team:	call: 'User/invite_team', use_form: 'UserInviteTeam'
					project_delete:	page:'project_delete', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						delete_project:	call: 'Directory/delete_project', use_fields: 'id', RESULTS: [
							r:{}, call: 'Directory/default_first_project', RESULTS: [
								r:{}, call: 'Pageflow/path', p:{path:'//landing'}
							]
						]
					project_clone:	page:'project_clone', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						create:	call: 'Directory/clone_project', use_form: 'CloneProject', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Directory/choose_project_view', use_result: 'project_id:id', RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
							]
						]
					project_rename:	page:'project_rename', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						rename:		call: 'Directory/rename_project', use_form: 'ProjectRename', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					project_add:	page:'project_add', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						create:		call: 'Directory/add_project', use_form: 'Project', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Directory/choose_project_view', use_result: 'project_id:id', RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
							]
						]
					template_add:	page:'template_add', modal: 'slide', CLICKS:
						close_modal:	macro: 'clear_landing'
						cancel:			macro: 'clear_landing'
						create:		call: 'Directory/add_template', use_form: 'Template', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					team_maint: page: 'team_maint', url: 'Directory/url_team', modal: 'slide', CLICKS:
						back:			call: 'Pageflow/path', p:{path:'//landing'}
						close_modal:	call: 'Pageflow/path', p:{path:'//landing'}
						cancel:			call: 'Pageflow/path', p:{path:'//landing'}
						add_as_member:	call: 'Directory/add_member', use_fields:'id', p:{as:'member'}, RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
						add_as_manager:	call: 'Directory/add_member', use_fields:'id', p:{as:'manager'}, RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
						add_as_owner:	call: 'Directory/add_member', use_fields:'id', p:{as:'owner'}, RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]
					progress: page: 'progress', modal: 'modal', CLICKS:
						close_modal: call:'Uploads/delete_active_on_finish_clean', go: '//landing'
						abort: call: 'Uploads/abort', RESULTS: [ r:{}, call: 'Pageflow/path', p:{path:'//landing'} ]
						show_progress: call: 'Pageflow/refresh'
						confirm_cancel: call: 'Uploads/confirm', use_fields: 'id', p:{answer:false}, RESULTS: [
							r:{}, call:'Pageflow/path', p:{path:'//landing'}
						]
						confirm_continue: call: 'Uploads/confirm', use_fields: 'id', p:{answer:true}
						cancel_progress: call: 'Uploads/delete', use_fields: 'id', RESULTS: [
							r:{}, call:'Pageflow/path', p:{path:'//landing'}
						]
						reload_error_files: call: 'Uploads/retry_all', use_fields: 'callback_class'
					download_abort: page: 'download_abort', modal: 'modal', CLICKS:
						close_modal:call: 'Pageflow/path', p:{path:'//landing'}
						abort:		call: 'Downloads/abort', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//landing'}
						]

		myprofile:
			template:'MyAccount', start: 'main'
			v:{ is_profile:0, is_projects:0, is_password:0, is_contact:0, is_privacy:0, is_subscription:0, is_sponsor:0, is_billing:0 }
			MACRO:
				clear_profile:	call: 'Sponsor/add_sponsor_close', p:{id:false}
			CLICKS:
				'Async.loaded': # The project-list was just now populated
					call: 'Pageflow/refresh'
				go_profile:  go: '/main/profile'
				go_projects: go: '/main/projects'
				go_password: go: '/main/password'
				go_contact:  go: '/main/contact'
				go_privacy_tab:  go: '/main/privacy'
				go_subscription: go: '/main/subscription'
				go_sponsor:  go: '/main/sponsor'
				go_billing:  go: '/bill/'
				go_invoice:	call: 'Billing/select_invoice', use_fields: 'id', RESULTS: [
					r:{success:'SUCCESS'}, go: '/bill/invoice'
				]
			TRACKS:
				main:
					start: 'subscription'
					CLICKS:
						AddNewTeamUser_onchange: call: 'Sponsor/update_new_sponsor_field', use_fields: 'id,input_obj,name'
						invite_team_user_row: call: 'Sponsor/invite_new_sponsor_row', use_fields: 'id'
						send_team_invites: call: 'Sponsor/send_new_sponsor_rows', use_form: 'AddNewTeamUser'
						cancel_team_invites: call: 'Sponsor/clear_new_sponsor_rows'
						close_modal:	call: 'Pageflow/path', p:{path:'/main/profile'}
						cancel:		call: 'Pageflow/path', p:{path:'/main/subscription'}
						change:		call: 'User/save_profile', use_form: 'ProfileEdit', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/profile'}
						]
						change_pass:		call: 'User/save_password', use_form: 'ChangePass', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/password'}
						]
						change_extended: call: 'User/save_profile_extended', use_form: 'ProfileExtended', RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/contact'}
							]
						change_expose: call: 'User/save_profile_expose', use_fields: 'onoffswitch,onoffswitch_orig', RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'/main/privacy'}
							]
						sponsor_del:		call: 'Sponsor/sponsor_del', use_fields: 'id', RESULTS: false
						remove_team_user_row:	call: 'Sponsor/remove_team_user_row', use_fields: 'id'
						add_sponsor_open:	call: 'Sponsor/add_new_sponsor_row'
						add_sponsor_close:	call: 'Sponsor/add_sponsor_close'
						add_sponsor_email:	call: 'Sponsor/sponsor_add', use_form: 'SponsorAddEmail', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Sponsor/add_sponsor_close'
						]
						go_new_user_email: call: 'User/have_email', use_fields:'email', RESULTS: [
							r:{}, call: 'Sponsor/add_sponsor_close', go:'/profile/user_add_from_profile'
						]
						set_as_standard:		call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'standard'}
						set_as_limited:			call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'limited'}
						set_as_team_member:		call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'team_member'}
						set_as_team_manager:	call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'team_manager'}
						set_as_team_creator:  	call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'team_creator'}
						set_as_team_accountant: call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'team_accountant'}
						set_as_team_admin:  	call: 'Sponsor/sponsor_level', 		use_fields:'id', p:{as:'team_admin'}
						modify_team_user:			call: 'Sponsor/choose_team_user', 	use_fields:'id'
						save_modify_team_user:		call: 'Sponsor/save_team_user', 	use_form:'ModifyTeamUser', RESULTS: [
							r:{success:'SUCCESS'}, 	call: 'Sponsor/choose_team_user'
						]
						cancel_modify_team_user:	call: 'Sponsor/choose_team_user'
						start_watching:	call: 'Directory/start_watch_project', use_fields: 'id,name', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Directory/choose_project_view', use_fields: 'id', RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'home//'}
							]
						]
						stop_watching:	call: 'Directory/stop_watch_project', use_fields: 'id'

					STEPS:
						profile:      page: "profile_edit_profile",        v:{is_profile:1}
						projects:     page: "team_maint_projects",         v:{is_projects:1}
						password:     page: "profile_change_password",     v:{is_password:1}
						contact:      page: "profile_contact_info",        v:{is_contact:1}
						privacy:      page: "profile_contact_info_expose", v:{is_privacy:1}
						subscription: page: "profile_subscription",        v:{is_subscription:1}
						sponsor:      page: "profile_team_users",          v:{is_sponsor:1}
						user_add_from_profile:	page:'user_invite', CLICKS:
							close_modal:	macro: 'clear_profile'
							cancel:			macro: 'clear_profile'
							create:		call: 'User/invite', use_form: 'UserInviteOther'
							create_team:	call: 'User/invite_team', use_form: 'UserInviteTeam'

				bill:
					start: 'overview', dom_cache: 'myoverview', v:{is_billing:1, billing_track: true}
					CLICKS:
						go_overview:  go: '//overview'
						go_select:    macro: 'go_billing_select'
						go_payment:   go: '//payment'
						go_card_change: go: '//card_change'
						go_billing_faqs: go: '//billing_faqs'
						go_remove_card: go: '//remove_card_confirm'
					STEPS:
						overview:   page: "bill_overview", dom_cache: 'myoverview', CLICKS:
							go_cancel_billing: go: '//cancel_yn'
							go_uncancel_billing: go: '//uncancel_yn'
						cancel_yn:   page: "bill_cancel_yn", modal:'slide', CLICKS:
							yes: call: 'Billing/cancel_plan', go: '//overview'
							no: go: '//overview'
							close_modal: go: '//overview'
						uncancel_yn:   page: "bill_uncancel_yn", modal:'slide', CLICKS:
							yes: call: 'Billing/uncancel_plan', go: '//overview'
							no: go: '//overview'
							close_modal: go: '//overview'
						remove_card_confirm:   page: "bill_remove_card_yn", modal:'slide', CLICKS:
							yes: call: 'Billing/remove_card', go: '//overview'
							no: go: '//overview'
							close_modal: go: '//overview'
						select:     page: "bill_select",   dom_cache: 'myoverview', CLICKS:
							back: go: '//overview'
							next: call: 'Billing/validate_plan_update', RESULTS: [
								r:{success:'SUCCESS'}, macro: 'go_payment'
							]
							onchange_ProfileAddon: call: 'Billing/onchange_ProfileAddon', use_fields: 'field,value'
							capacity_plus:  call: 'Billing/capacity_plus'
							capacity_minus: call: 'Billing/capacity_minus'
							user_plus:      call: 'Billing/user_plus'
							user_minus:     call: 'Billing/user_minus'
							select_plan:    call: 'Billing/select_plan', use_fields: 'prefix', RESULTS: [
								r:{}, call: 'Pageflow/refresh'
							]
						card_enter:  page: "bill_card_edit", dom_cache: 'myoverview', CLICKS:
							cancel: go: '//payment'
							update: call: 'Billing/update_card', use_form: 'CardInfo', RESULTS: [
								r:{success:'SUCCESS'}, go: '//review'
							]
						payment: page: "bill_payment",      dom_cache: 'myoverview', CLICKS:
							change: go: '//card_enter'
							next: go: '//review'
						review:    page: "bill_review",     dom_cache: 'myoverview', CLICKS:
							purchase: call: 'Billing/purchase', RESULTS: [
								r:{success:'SUCCESS'}, go: '//processed'
							]
						processed:  page: "bill_processed", dom_cache: 'myoverview'
						invoice:    page: "bill_invoice",   dom_cache: 'myoverview'
						card_change:  page: "bill_card_change", dom_cache: 'myoverview', CLICKS:
							cancel: go: '//overview'
							update: call: 'Billing/update_card', use_form: 'CardInfo', RESULTS: [
								r:{success:'SUCCESS'}, go: '//overview'
							]
						billing_faqs: page: "billing_faqs", dom_cache: 'myoverview'

		admin:
			start: 'main'
			template: 'Admin'
			CLICKS:
				go_home:		call: 'Pageflow/path', p:{path:'home//'}
			TRACKS:
				main: start:'users', STEPS:

					projects:	page:'admin_projects', CLICKS:
						admin_start_watching:	call: 'Directory/start_watch_project', use_fields: 'id,name', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Directory/choose_project_view', use_fields: 'id', RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'home//'}
							]
						]
						admin_stop_watching:	call: 'Directory/stop_watch_project', use_fields: 'id'

					prereg:	page:'admin_prereg', CLICKS:
						prereg_state:	call: 'Admin/prereg_state', use_fields: 'state_code'
						prereg_invite:
							call: 'User/populate_invite'
							use_fields: 'name,first_name,last_name,email,city,state,id:invite_id'
							RESULTS: [
								r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//user_add_ltd'}
							]
					user_add_ltd:	page:'user_invite_ltd', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//prereg'}
						cancel:			call: 'Pageflow/path', p:{path:'//prereg'}
						create:		call: 'User/invite_admin_ltd', use_form: 'UserInviteAdamLtd', RESULTS: [
							{ r:{ success:'SUCCESS'},	call: 'Pageflow/path', p:{path:'//prereg'} }
						]
					user_add:	page:'user_invite', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//prereg'}
						cancel:			call: 'Pageflow/path', p:{path:'//prereg'}
						create:		call: 'User/invite_admin', use_form: 'UserInviteAdam', RESULTS: [
							{ r:{ success:'SUCCESS'},	call: 'Pageflow/path', p:{path:'//prereg'} }
						]

					users:	page:'admin_users', CLICKS:
						admin_user_sponsors: call: 'Admin/choose_user_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//user_sponsors'}
						]
						admin_user_edit: call: 'Admin/choose_user_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//user_edit'}
						]
						admin_user_disable: call: 'Admin/choose_user_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//user_disable'}
						]
						admin_user_edit_level: call: 'Admin/choose_user_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//user_level'}
						]
					bankcheck:	page:'admin_bankcheck', CLICKS:
						admin_user_edit_bankcheck: call: 'Admin/choose_user_edit', use_fields: 'id', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Admin/bankcheck_clear', go: '//user_bankcheck'
						]

					user_bankcheck:	page:'admin_user_bankcheck', CLICKS:
						cancel:		call: 'Admin/bankcheck_clear', RESULTS: [
							r:{},	call: 'Pageflow/path', p:{path:'//bankcheck'}
						]
						onchange_AdminUserEditBankcheck: call: 'Admin/onchange_bankcheck', use_fields: 'field,value'
						save:		call: 'Admin/user_save_bankcheck_temp', use_form: 'AdminUserEditBankcheck', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//user_bankcheck_confirm'}
						]
					user_bankcheck_confirm:	page:'admin_user_bankcheck_confirm', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//user_bankcheck'}
						cancel:			call: 'Pageflow/path', p:{path:'//user_bankcheck'}
						save:		call: 'Admin/user_save_bankcheck', use_form: 'AdminUserEditBankcheck', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//bankcheck'}
						]

					user_sponsors:	page:'admin_user_sponsors', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//users'}
						cancel:			call: 'Pageflow/path', p:{path:'//users'}
						sponsor_del:		call: 'Admin/sponsor_del', use_fields: 'id', RESULTS: false
						add_sponsor_open:	call: 'Admin/add_sponsor_open'
						add_sponsor_close:	call: 'Admin/add_sponsor_close'
						add_sponsor_email:	call: 'Admin/sponsor_add', use_form: 'AdminSponsorAddEmail', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Admin/add_sponsor_close'
						]
						go_new_user_email: call: 'Admin/have_email', use_fields:'email', RESULTS: [
							r:{}, call: 'Admin/add_sponsor_close', RESULTS: [
								r:{}, call:'Pageflow/path', p:{path:'//user_add_from_sponsors'}
							]
						]
						set_as_team_member:	call: 'Admin/sponsor_level', use_fields:'id', p:{as:'team_member'}
						set_as_team_manager:call: 'Admin/sponsor_level', use_fields:'id', p:{as:'team_manager'}
						set_as_team_creator:  call: 'Admin/sponsor_level', use_fields:'id', p:{as:'team_creator'}
						set_as_team_accountant:  call: 'Admin/sponsor_level', use_fields:'id', p:{as:'team_accountant'}
						set_as_team_admin:  call: 'Admin/sponsor_level', use_fields:'id', p:{as:'team_admin'}
					user_add_from_sponsors:	page:'user_invite_forteam', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//user_sponsors'}
						cancel:			call: 'Pageflow/path', p:{path:'//user_sponsors'}
						create:		call: 'Admin/invite_for_team', use_form: 'UserInviteForTeam', RESULTS: [
							r:{ success:'SUCCESS' },	call: 'Admin/add_sponsor_close', RESULTS: [
								{ r:{ },	call: 'Pageflow/path', p:{path:'//user_sponsors'} }
							]
						]
					user_edit:	page:'admin_user_edit', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//users'}
						cancel:			call: 'Pageflow/path', p:{path:'//users'}
						save:		call: 'Admin/user_save', use_form: 'AdminUserEdit', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//users'}
						]
					user_disable:	page:'admin_user_disable', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//users'}
						cancel:			call: 'Pageflow/path', p:{path:'//users'}
						disable:		call: 'Admin/user_disable', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//users'}
						]
					user_level:	page:'admin_user_level', modal: 'slide', CLICKS:
						close_modal:	call: 'Pageflow/path', p:{path:'//users'}
						cancel:			call: 'Pageflow/path', p:{path:'//users'}
						save:		call: 'Admin/user_save_level', use_form: 'AdminUserEditLevel', RESULTS: [
							r:{success:'SUCCESS'}, call: 'Pageflow/path', p:{path:'//users'}
						]
					test: page: 'admin_test', CLICKS:
						send: call:'Admin/email_test', use_form: 'AdminEmailTest'
					pstats: page: 'admin_pstats'
