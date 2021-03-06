window.EpicMvc.fist$ipm=
	FIELDS:
		InviteTokenHide: { db_nm:'code',   type:'hidden'}
		InviteToken: { db_nm:'code',   type:'text',     req:true, h2h:'trim_spaces', label:'Invite code' }
		AuthEmailHide: { db_nm: 'email', type: 'hidden' }
		AuthProjectHide: { db_nm: 'project_id', type: 'hidden' }
		InviteIdHide: { db_nm: 'invite_id', type: 'hidden' }
		Email:
			db_nm:'email',    type:'text',     req:true, h2h:'trim_spaces', label:'Email Address',
			validate: 'email', req_text: 'Email Address is required.',
			issue_text: 'You have entered an invalid email address. Please review.'
		AuthEmail:
			db_nm:'email',    type:'text',     req:true, h2h:'trim_spaces', label:'Email Address',
			validate: 'email', req_text: 'Email Address is required.',
			issue_text: 'You have entered an invalid email address. Please review.'
		LoginPass: # Not validated for strength
			db_nm:'password', type:'password', req:true, h2h:'trim_spaces', label:'Password',
		AuthPass:
			db_nm:'password', type:'password', req:true, h2h:'trim_spaces', label:'Password',
			validate: 'ipm_password', issue_text: 'Password must be at least 6 characters and have 1 or more number(s). <br>No spaces, but you can use ! @ # $ % ^ & * to increase complexity.'
		ConfirmPass:
			db_nm:'confirm_pass', type:'password', h2h:'trim_spaces', label:'Confirm Password', req:true
			validate: 'confirm', validate_expr: 'AuthPass',
			issue_text: 'Passwords do not match. Please re-enter.  Passwords are case sensitive.'
		Level:       { db_nm:'level',type:'pulldown:custom', label:'Level', default: 'standard' }
		LevelTeam:    { db_nm:'level',type:'pulldown:custom', label:'Level', default: 'team_member' }
		LevelEffect:
			db_nm:'level_effect',type:'pulldown:array', label:'Membership', default: 'none'
			cdata: [
				[ 'none',	'No change to existing membership' ]
				[ 'class',	'Update "class" (not publically viewable)' ]
				[ 'invited','Update "invited_as" (publically viewable)' ]
				[ 'all',	'Update invited_as and disable owned projects' ]
			]
		EmailName:  { db_nm:'name',  type:'text', req:true, h2h:'trim_spaces', label: 'Recipient Name' }
		EmailMsg:  { db_nm:'msg',  type:'textarea', attrs: "", h2h:'trim_spaces', label: 'Personal note' }
		FirstName:  { db_nm:'first_name',  type:'text', req:true, h2h:'trim_spaces', label: 'First Name' }
		LastName:   { db_nm:'last_name',   type:'text', req:true, h2h:'trim_spaces', label: 'Last Name' }
		Company:    { db_nm:'company',     type:'text', req:true, h2h:'trim_spaces', label: 'Company name' }
		TradeSkill: { db_nm:'trade_skill', type:'text', req:true, h2h:'trim_spaces', label: 'Trade/Skill' }

		Phone:		{ db_nm:'office', type:'text', req:true, h2h:'trim_spaces', label: 'Phone ###-###-####' }

		# Extended profile fields
		#  mobile, office, fax, website, street1, street2, city, state, country, postal_code
		Mobile:		{ db_nm:'mobile', type:'text', h2h:'trim_spaces', label: 'Mobile' }
		Office:		{ db_nm:'office', type:'text', h2h:'trim_spaces', label: 'Office' }
		Fax:		{ db_nm:'fax',    type:'text', h2h:'trim_spaces', label: 'Fax' }
		Website:	{ db_nm:'website',type:'text', h2h:'trim_spaces', label: 'Website' }
		Street1:	{ db_nm:'street1',type:'text', h2h:'trim_spaces', label: 'Street' }
		Street2:	{ db_nm:'street2',type:'text', h2h:'trim_spaces', label: 'Line 2' }
		City:		{ db_nm:'city',   type:'text', h2h:'trim_spaces', label: 'City' }
		State:		{ db_nm:'state',  type:'pulldown:custom', h2h:'trim_spaces', label: 'State', choice: 'Choose State'}
		StateReq:	{ db_nm:'state',  type:'pulldown:custom', h2h:'trim_spaces', label: 'State', choice: 'Choose State', req:true}
		Country:	{ db_nm:'country',type:'hidden', h2h:'trim_spaces', label: 'Country' }
		PostalCode:	{ db_nm:'postal_code', type:'text', h2h:'trim_spaces', label: 'Postal code' }

		ExtraMbytesQuota:  { db_nm:'extra_quota',        type:'text', req:true, h2h:'digits_only',label: 'Extra Quota (MB)' }
		ExtraSponsorships: { db_nm:'extra_sponsorships', type:'text', req:true, h2h:'digits_only',label: 'Extra Sponsorships' }

		ExtraGBlocks:{ db_nm:'extra_gblocks',type:'text', width:2, h2h:'digits_only',label: '' }
		ExtraUsers:  { db_nm:'extra_users',  type:'text', width:2, h2h:'digits_only',label: '' }

		FolderName: { db_nm:'name', type:'text', req:true, label: 'Folder Name'}

		FileName:   { db_nm:'name', type:'text', req:true, label: ' '}
		FileSize:   { db_nm:'size', type:'text', req:true, label: 'Enter size in bytes'}

		ProjectName: { db_nm:'name', type:'text', req:true, label: 'Project Name', req_text:'Project Name is a required field.'}
		TemplateName:{ db_nm:'name', type:'text', req:true, label: 'Template Name'}
		Template:
			db_nm:'project_id',type:'pulldown:custom', req:true,
			label: 'Select a Template', custom: first: 'No Template'
		Project:     { db_nm:'project_id',type:'radio:custom', req:true, label: 'Source project', }
		AskFiles:
			db_nm:'include_files', type:'radio:array', req:true, label: 'Clone options:'
			cdata: [[0,'Folders only'], [1,'Folders and Files']], default: 0
			validate: 'choice', h2d: 'zero_is_blank', d2h: 'blank_is_zero'
		AskTeam:    { db_nm:'include_team', type:'yesno', label: 'Include Team' }
		AskVersions:    { db_nm:'include_versions', type:'yesno', label: 'Include Versions' }
		TermsConfirm:    { db_nm:'terms_accept', type:'yesno', req:true, label: ' ' }
		PrivacyConfirm:  { db_nm:'privacy_accept', type:'yesno', req:true, label: ' ' }

		TeamEmail:
			db_nm:'email', type:'text', req:true, h2h:'trim_spaces', label:'Enter email'
			validate: 'email', issue_text: 'invalid email'
		AskSponsor:  { db_nm:'sponsor', type:'yesno', cdata:'yes', label: 'Sponsor this user?' }

		CcName:{ db_nm:'cc_name', type:'text',req:true, label: 'Name on Credit Card'}
		CcNum:
			db_nm:'cc_num', type:'text', req:true, label: 'Credit Card Number'
			h2h:'digits_only', validate:'ccnum'
		CcCvv:
			db_nm:'cc_cvv', type:'text', req:true, label: 'CVV'
			h2h:'digits_only', validate: 'regexp', validate_expr: '[0-9]{3,4}'
			req_text: 'CVV must be 3 or 4 digits (check the back of your card)'
			issue_text: 'CVV must be 3 or 4 digits (check the back of your card)'
		CcMonth:
			db_nm:'cc_month', type:'pulldown:array', req:true, label: 'Month',
			cdata: ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12' ]
		CcYear:
			db_nm:'cc_year', type:'pulldown:array', req:true, label: 'Year',
			cdata: ['2014', '2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024']
		CcZip:
			db_nm:'cc_zip', type:'text', req:true, label: 'Zip Code'
			validate:'zip', validate_expr: '5or9'

		BcPlanChoice:	{ db_nm:'plan_id',type:'pulldown:custom', req:true, label: 'Plan'}
		BcSponsorships:	{ db_nm:'extra_spships',type:'text', req:true, validate:'number', label: 'Extra sponsorships'}
		BcGBlocks:		{ db_nm:'extra_gblocks',     type:'text', req:true, validate:'number', label: 'Extra 50GB blocks'}
		BcCheckTotal:
			db_nm:'check_total', type:'text', req:true, label: 'Amount on check'
			validate:'money', h2d: 'money', d2h: 'money'
			issue_text: 'Must be in the format #.##'
		BcMonths:		{ db_nm:'months',      type:'text', req:true, validate:'number', label: 'Months purchased'}
		BcCheckRef:		{ db_nm:'check_ref',   type:'text', req:true, label: 'Check number/ref'}
		BcInvoiceRef:	{ db_nm:'invoice_ref', type:'text', req:true, label: 'Invoice number/ref'}
		BcNotePrivate:	{ db_nm:'note_private',type:'textarea', attrs: "maxlength='1024'", label: 'Private notes (1024)'}
		BcNotePublic:	{ db_nm:'note_public', type:'textarea', attrs: "maxlength='1024'", label: 'Public notes (1024)'}
		AetEmail:
			db_nm:'email', type:'text', req:true, h2h:'trim_spaces', label:'Destination email'
			validate: 'email', issue_text: 'invalid email'
		AetTemplate:
			db_nm:'template', type:'pulldown:array', req:true, label: 'Template', cdata: [
				'SendForgot', 'SendInvite', 'SendProjectInvite', 'SendTeamInvite', 'SendTeamProjectInvite',
        		'SendReRegister', 'SendSignUpConfirmation', 'SendSignUpComplete', 'SendProjectRestricted',
        		'SendProjectRestrictedManager', 'SendProjectTransferSuccess', 'SendProjectTransferLevelFail',
        		'SendProjectTransferMaxFail', 'SendProjectTransferQuotaFail', 'SendProjectCreateQuotaFail',
        		'SendFreeTrialExpired', 'SendBTPlanPurchase', 'SendBTPlanCharge', 'SendBTPlanNoCharge',
	            'SendCheckPlanPurchase', 'SendPaidPlanExpired', 'SendGeneralProjectNotification',
	            'SendBTPlanCancel', 'SendBTPlanUnCancel'
			]
		AetTestData:
			db_nm:'test_data', type:'pulldown:array', req:true, label: 'Source Data', cdata: ['T1', 'Notice1', 'BT', 'BC']
		AdminExpires:    { db_nm:'expires',     type:'text', h2h:'trim_spaces', label: 'Expires (m/d/yyyy or #days); Free Trial and Free Users Only' }
		SendToChoice:
			db_nm:'send_option', type:'radio:array', req:true, label: 'Send to:', default: 'all', validate: 'choice'
			cdata: [['all','All project members'], ['management','Owner and project managers only'], ['list','Selected Members Only']]
		Body: { db_nm:'body',type:'textarea', attrs: "maxlength='1024' style='width:98%;min-height:100px;' placeholder='Type your message here...'", label: 'Message:', default: ''}
		ProjectLink: db_nm:'link_flag', type:'yesno', label: 'Include Project Link'

	FISTS:
		Login:	[ 'AuthEmail', 'LoginPass' ]
		Folder:	[ 'FolderName' ]
		File:	[ 'FileName' ]
		RequestInvite: [ 'FirstName', 'LastName', 'Email' ]
		UserRegister: [
			'InviteTokenHide', 'AuthEmail', 'FirstName', 'LastName', 'Company', 'AuthPass', 'ConfirmPass'
			,'City' ,'StateReq', 'Phone', 'TermsConfirm','PrivacyConfirm' ]
		UserInviteProject: [ 'FirstName', 'LastName', 'AuthEmail' ]
		UserInviteProjectAdam: [ 'FirstName', 'LastName', 'AuthEmail', 'Level' ]
		UserInviteOther: [ 'FirstName', 'LastName', 'AuthEmail', 'EmailMsg', 'AuthProjectHide' ] # W/o level
		UserInviteTeam:  [ 'FirstName', 'LastName', 'AuthEmail', 'EmailMsg', 'AuthProjectHide' ] # Team-admin invites new email to team
		UserInviteForTeam: [ # W/AskSponsor; Admin on behalf of Pro-user
			'FirstName', 'LastName', 'AuthEmail', 'EmailMsg' ,'AskSponsor'
		]
		UserInviteAdam:    [ 'FirstName', 'LastName', 'AuthEmail', 'EmailMsg', 'Level' ,'AuthProjectHide'  ]
		UserInviteAdamLtd: [                                       'EmailMsg', 'Level' ,'InviteIdHide' ] # W/o fields from i2_invites
		UserForgot:	[ 'AuthEmail' ]
		UserForgotFinish:	[ 'InviteTokenHide', 'AuthEmailHide', 'AuthPass', 'ConfirmPass' ]
		ChangePass:	[ 'AuthPass', 'ConfirmPass' ]
		Project:	[ 'ProjectName', 'Template' ]
		CloneProject:	[ 'ProjectName', 'AskFiles', 'AskTeam', 'AskVersions' ]
		Template:	[ 'TemplateName' ]
		TeamAddEmail: ['TeamEmail']
		SponsorAddEmail: ['TeamEmail']
		ProjectRename:	[ 'ProjectName' ]
		ProfileEdit: [ 'FirstName', 'LastName', 'Company', 'Email' ]
		ProfileExtended: [ 'Mobile', 'Office', 'Fax', 'Website', 'Street1', 'Street2', 'City', 'State', 'Country', 'PostalCode' ]
		ProfileAddon: [ 'ExtraGBlocks', 'ExtraUsers' ]

		AdminUserEdit: [ 'ExtraMbytesQuota' ,'ExtraSponsorships', 'AdminExpires' ]
		AdminUserEditLevel: [ 'Level' ,'LevelEffect' ]
		AdminSponsorAddEmail: ['TeamEmail']
		CardInfo:[ 'CcName' ,'CcNum' ,'CcCvv' ,'CcMonth' ,'CcYear' ,'CcZip' ]
		ModifyTeamUser: ['FirstName','LastName','TeamEmail']
		AddNewTeamUser: ['FirstName','LastName','TeamEmail','LevelTeam']
		AdminUserEditBankcheck: ['BcPlanChoice', 'BcMonths', 'BcSponsorships', 'BcGBlocks', 'BcCheckTotal', 'BcCheckRef', 'BcInvoiceRef', 'BcNotePrivate', 'BcNotePublic']
		AdminEmailTest: ['AetEmail', 'AetTemplate', 'AetTestData' ]
		ComposeNotify: ['SendToChoice','Body','ProjectLink']
