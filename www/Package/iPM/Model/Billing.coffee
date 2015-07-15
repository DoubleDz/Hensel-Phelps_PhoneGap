
class Billing extends window.EpicMvc.ModelJS
	constructor: (Epic,view_nm) ->
		ss=
			new_plan_id: false
		super Epic, view_nm, ss
		@rest= window.EpicMvc.Extras.Rest # Static class
		@_reset()
	eventLogout: -> true # blow me away
	eventNewRequest: (change) ->
		return if @c_billing is false
		return if change.track isnt true # Below here we flush the cache as they move out of this track
		return if ( @Epic.getViewTable 'Pageflow/V')[0].billing_track is true # TODO HACK TO DETECT INBOUND TO THIS TRACK
		@_reset()
		( @Epic.getFistInstance 'CardInfo').clearValues()
	_reset: (force) ->
		@c_billing= false # have we loaded (or need to load) billing info via REST?
		me=( @Epic.getInstance 'User')._getMyself force # Force reset of c_users
		if me.users[0].bill_system is 1
			plan_prefix=( me.users[0].bill_state?.split '-')[1]
			@c_selected_plan=
				extra_gblocks: me.payment.gblock_qty, extra_users: me.payment.spship_qty, prefix: plan_prefix
			@c_current_plan= $.extend {}, @c_selected_plan # To compare with
			delete @c_card_info
			delete @c_history
			delete @c_recommend
		@c_invoice_detail= false
		@invalidateTables true

	action: (act,p) ->
		f= "M:Billing::action(#{act})"
		_log f, p
		r= {}; i= new window.EpicMvc.Issue @Epic, @view_nm, act; m= new window.EpicMvc.Issue @Epic, @view_nm, act
		@_getBilling()
		switch act
			when 'check_for_card' # app wants to know, for flow processing
				r.card= if 'last4' of @_getCardInfo() then 'YES' else 'NO'
			when 'select_invoice' # p.id
				result= @rest.get 'User/me/History/'+ p.id, f
				if 'history' of result
					@c_invoice_detail= result.history
					@invalidateTables ['SelectedInvoice']
					r.success= 'SUCCESS'
				else m.add 'NO_HISTORY_ID', p.id
			when 'select_plan_default' # p.prefix
				if @c_selected_plan.prefix in ['TRIAL','FREE']
					if @c_recommend.plan
						@c_selected_plan.prefix= @c_recommend.plan.prefix
						@c_selected_plan.extra_users= @c_recommend.plan.min_extra_users
						@c_selected_plan.extra_gblocks= @c_recommend.plan.min_extra_gblocks
					@invalidateTables ['SelectedPlan']
			when 'select_plan' # p.prefix
				if p.prefix isnt @c_selected_plan.prefix
					plan_ok=!@c_recommend? or ( @c_recommend.ordered_levels.indexOf @c_recommend.min_req_level)<=
						@c_recommend.ordered_levels.indexOf @c_braintree[p.prefix].level
					if plan_ok
						@c_selected_plan.prefix= p.prefix
						@invalidateTables ['SelectedPlan']
						r.success= 'SUCCESS'
					else
						i.add 'PLAN_TOO_LOW', [@c_recommend.plan.plan_name]
						r.success= 'FAIL'
			when 'capacity_plus' ,'capacity_minus' ,'user_plus' ,'user_minus'
				m= capacity: 'extra_gblocks', user: 'extra_users', plus: 1, minus: -1
				f= capacity: 'ExtraGBlocks', user: 'ExtraUsers'
				[who,what]= act.split '_'
				val= @c_selected_plan[m[who]]
				val+= m[what]
				val= 0 if val< 0
				if @c_selected_plan[ m[ who]] isnt val
					@c_selected_plan[ m[ who]]= val
					oF = @Epic.getFistInstance 'ProfileAddon'
					oF.fb_HTML[ f[ who]]= val # An HTML puppet
					@invalidateTables ['SelectedPlan']
			when 'onchange_ProfileAddon' # p.field, p.value
				m= ExtraGBlocks: 'extra_gblocks', ExtraUsers: 'extra_users'
				val= Number p.value
				val= 0 if isNaN val # Non numbers return to 0
				oF = @Epic.getFistInstance 'ProfileAddon'
				oF.fb_HTML[ p.field]= p.value # An HTML puppet
				if @c_selected_plan[m[p.field]] isnt val
					@c_selected_plan[m[p.field]]= val
					@invalidateTables ['SelectedPlan']
				r.success= 'SUCCESS'
			when 'validate_plan_update' # Has the plan/addons changed? Is this plan 'ok'?
				# Check plan, before checking plan-addons
				plan= @c_braintree[@c_selected_plan.prefix]
				plan_ok=( @c_recommend.ordered_levels.indexOf @c_recommend.min_req_level)<=
					@c_recommend.ordered_levels.indexOf plan.level
				gblocks_ok= @c_selected_plan.extra_gblocks >= @c_recommend.plans[plan.level].min_extra_gblocks
				users_ok= @c_selected_plan.extra_users >= @c_recommend.plans[plan.level].min_extra_users
				if not plan_ok
					i.add 'PLAN_TOO_LOW', [@c_recommend.plan.plan_name]
					r.success= 'FAIL'
					return [ r, i, m]
				else if not gblocks_ok or not users_ok
					i.add 'GBLOCKS_TOO_LOW', [@c_recommend.plans[plan.level].min_extra_gblocks] if not gblocks_ok
					i.add 'USERS_TOO_LOW', [@c_recommend.plans[plan.level].min_extra_users] if not users_ok
					r.success= 'FAIL'
					return [ r, i, m]

				good= false # If something is different then changed to true
				good= true if @c_selected_plan.prefix isnt @c_current_plan.prefix
				if @c_braintree[@c_selected_plan.prefix].gblock_price
					good= true if @c_selected_plan.extra_gblocks isnt @c_current_plan.extra_gblocks
				if @c_braintree[@c_selected_plan.prefix].spship_price
					good= true if @c_selected_plan.extra_users isnt @c_current_plan.extra_users
				if good
					r.success= 'SUCCESS'
				else
					i.add 'NO_PLAN_CHANGE'
					r.success= 'FAIL'
			when 'purchase'
				fv= $.extend {}, @c_selected_plan
				plan= @c_braintree[@c_selected_plan.prefix]
				fv.plan_id= plan.id
				fv.extra_gblocks= 0 if plan.gblock_price is 0
				fv.extra_users= 0 if plan.spship_price is 0
				result= @rest.post 'User/me/purchase', f, fv
				if result.SUCCESS is true
					@_reset true # Force re-read of User/me endpoint to populate 'payment' record
					(@Epic.getInstance 'User' ).UpdateUserAsync 'merge', result.updated_user
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'update_card' # fist: CardInfo
				oF = @Epic.getFistInstance 'CardInfo'
				i.call oF.fieldLevelValidate p # Will populate DB side
				@_checkCcExp i, oF
				if i.count() > 0 then r.success= 'FAIL'; return [r, i, m]
				fv= @_encryptFields oF.getDbFieldValues()
				result= @rest.post "User/me/account" , f, fv
				if result.SUCCESS is true
					@c_card_info= result.card
					if result.retry_sub is true
						if result.retry_result is true
							m.add 'RETRY_SUB_SUCCESS'
						else
							i.add 'RETRY_SUB_FAIL'
					oF.clearValues() # Important, to keep CC values from being stored
					@invalidateTables ['MyCard']
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'cancel_plan'
				result= @rest.post 'User/me/cancelplan', f, fv
				if result.SUCCESS is true
					#TODO @_reset true ?
					(@Epic.getInstance 'User' ).UpdateUserAsync 'merge', result.updated_user
					@invalidateTables ['MyCard']
					m.add 'PLAN_CANCEL'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'uncancel_plan'
				result= @rest.post 'User/me/uncancelplan', f, fv
				if result.SUCCESS is true
					#TODO @_reset true ?
					(@Epic.getInstance 'User' ).UpdateUserAsync 'merge', result.updated_user
					@invalidateTables ['MyCard']
					m.add 'PLAN_UNCANCEL'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			when 'remove_card'
				result= @rest.post 'User/me/removeaccount', f, fv
				if result.SUCCESS is true
					@invalidateTables ['MyCard']
					m.add 'CARD_REMOVED'
					r.success= 'SUCCESS'
				else
					@rest.makeIssue i, result
					r.success= 'FAIL'
			else return super act, p
		#_log2 f, 'return', r, i, m
		[r, i, m]
	loadTable: (tbl_nm) ->
		f= "M:Billing::loadTable(#{tbl_nm})"
		#_log2 f
		@_getBilling()
		switch tbl_nm
			when 'Bankcheck'
				table= []
				for nm,row of @c_bank_check
					new_row= $.extend {}, row
					table.push new_row
				@Table[tbl_nm]= table
			when 'Plan'
				myPlanState=( @Epic.getViewTable 'User/Me')[0].bill_state?.split '-'
				( @Table[tbl_nm]= []; return) if not myPlanState
				table= []
				for key,row of @c_braintree when key not in ['TRIAL','FREE']
					new_row= $.extend {}, row, is_current: ''
					new_row.join= @rest.choices().bt_plans.prefix[row.prefix].join
					new_row.create= @rest.choices().bt_plans.prefix[row.prefix].create
					new_row.manage= @rest.choices().bt_plans.prefix[row.prefix].manage
					new_row.is_join_unlimited= if new_row.join is 999999 then 'yes' else ''
					new_row.is_create_unlimited= if new_row.create is 999999 then 'yes' else ''
					if row.token is myPlanState[1] # Token, like 'TRIAL' or 'PRO'
						new_row.is_current= 'yes'
					new_row.users= 1+ row.base_spships
					table.push new_row
				table.sort (a,b) -> a.base_price- b.base_price
				@Table[tbl_nm]= table
			when 'Overview'
				myself=( @Epic.getInstance 'User')._getMyself()
				me= myself.users[0]
				( @Table[ tbl_nm]=[plan_name: 'Admin']; return) if me.bill_system is 0
				myPlanState= me.bill_state.split '-'
				if me.bill_system is 2
					row= $.extend {}, @c_bank_check_prefixed[ myPlanState[ 1]], myself.payment, myself.stats
				else
					row= $.extend {Recommend:[ ]}, @c_braintree[ myPlanState[ 1]], myself.payment, myself.stats
					row.Recommend= [$.extend {}, myself.plan] if myself.is_recommendation
				row.allowed_gigs=( row.mbytes_quota+ me.extra_quota)/ 1024 #TODO: extra_quota not fully implemented
				row.allowed_users= (Number row.sponsorships) + (Number me.extra_sponsorships) + 1 #TODO: extra_sponsorships not fully implemented
				row.total= row.base_price+ row.spship_qty* row.spship_price+ row.gblock_qty* row.gblock_price
				_log2 f, row.prefix, @rest.choices().bt_plans.prefix[ row.prefix]
				$.extend row, @rest.choices().bt_plans.prefix[ row.prefix]
				@Table[tbl_nm]= [row]
			when 'MyCard'
				myself=( @Epic.getInstance 'User')._getMyself()
				me= myself.users[0]
				( @Table[ tbl_nm]=[is_card: '']; return) if me.bill_system is 0
				myPlanState= me.bill_state.split '-'
				card_info= @_getCardInfo()
				row= $.extend {
					is_card: '', can_cancel: '', is_canceled: '', nextBillDate :''
					billingPeriodStartDate: '', billingPeriodEndDate: ''
					}, card_info
				if 'last4' of row
					row.is_card= true if 'last4' of row
					dt= new Date ( Date.parse row.billingPeriodEndDate+ 'T00:00:00Z')+ 24* 60* 60* 1000
					row.nextBillDate=  "#{dt.getUTCFullYear()}-#{dt.getUTCMonth()+1}-#{dt.getUTCDate()}"
					_log2 f, me.bill_system, myPlanState
					row.is_canceled= 'yes' if myPlanState[2] is 'CANCELED'
					if me.bill_system is 1 and myPlanState[2] isnt 'CANCELED' and myPlanState[1] not in ['TRIAL','FREE']
						row.can_cancel= 'yes'
				@Table[tbl_nm]= [row]
			when 'SelectedInvoice'
				row= $.extend {has_moreSpace: '', has_moreUsers: '', is_prorated: ''},
					@c_invoice_detail
					@rest.choices().bt_invoice.planId[ @c_invoice_detail.planId]
				total= 0
				# addOns[0,1].id is 'Storage_space_50' or 'users'
				addon_map= Storage_Space_50: 'moreSpace', User_Add_On: 'moreUsers'
				o_list=
					creditCard: row.creditCard
					subscription: row.subscription
					plan: @c_braintree[ row.prefix]
				for rec in row.addOns
					o_list[ addon_map[ rec.id]]= rec
					row['has_'+ addon_map[ rec.id]]= 'yes'
					total+=( row.moreSpace_extendedAmount= rec.amount* rec.quantity)
				for group_nm,rec of o_list
					row[group_nm+'_'+nm]= rec[nm] for nm of rec
				total=( Math.floor total* 100)+ row.plan_base_price
				row.total_amount= total
				row.is_prorated= 'yes' if total isnt ( Math.floor row.amount* 100)
				@Table[ tbl_nm]= [ row]
			when 'Invoice'
				myself=( @Epic.getInstance 'User')._getMyself()
				me= myself.users[0]
				( @Table[tbl_nm]= []; return) if me.bill_system is 0
				if me.bill_system is 2
					row= myself.payment
					@Table[tbl_nm]= [row]
				else
					@Table[tbl_nm]= @_getHistory()
			when 'SelectedPlan'
				r= @c_selected_plan # Shortcut
				row= $.extend {is_selected: '', total: 0, prefix:''}, @c_selected_plan
				if r.prefix?.length
					row.is_selected= 'yes'
					_log2 f, 'old row', row, 'prefix', r.prefix, 'braintree', @c_braintree[r.prefix]
					$.extend row, @c_braintree[r.prefix], @rest.choices().bt_plans.prefix[r.prefix]
					gblocks= if row.gblock_price isnt 0 then r.extra_gblocks else 0
					users= if row.spship_price isnt 0 then r.extra_users else 0
					row.extra_gblocks= gblocks
					row.extra_users= users
					row.extra_gblocks_price= gblocks* row.gblock_price
					row.extra_users_price= users* row.spship_price
					row.total= row.extra_gblocks_price+ row.extra_users_price+ row.base_price
					row.users= 1+ row.base_spships
				@Table[tbl_nm]= [row]

			else return super tbl_nm
		#_log2 f, 'after', @Table[tbl_nm]
		return
	fistLoadData: (oFist) ->
		f= "M:Billing.fistLoadData(#{oFist.getFistNm()})"
		switch oFist.getFistNm()
			when 'ProfileAddon'
				oFist.setFromDbValues @c_selected_plan
			when 'CardInfo'
				card_info= @_getCardInfo()
				if 'last4' of card_info # We have a winner
					vals=
						cc_name: card_info.cardholderName, cc_num: card_info.last4,
						cc_month: card_info.expirationMonth, cc_year: card_info.expirationYear, cc_zip: card_info.postalCode
				else
					# Dates default to start from current month/year
					now= new Date()
					m= now.getMonth()+ 1
					pad= if m< 10 then '0' else ''
					vals= cc_month: pad+( String m), cc_year:( String now.getFullYear())
				oFist.setFromDbValues vals
			else return super oFist
	_getRecommend: () ->
		f= "M:Billing._getRecommend"
		return @c_recommend if @c_recommend
		rest_results= @rest.get 'User/me/recommendplan', f
		@c_recommend= rest_results
		# Patch negative values to be 0
		if @c_recommend.plan
			@c_recommend.plan.min_extra_users= 0 if @c_recommend.plan.min_extra_users< 0
			@c_recommend.plan.min_extra_gblocks= 0 if @c_recommend.plan.min_extra_gblocks< 0
		return @c_recommend
	_getBilling: () ->
		f= "M:Billing._getBilling"
		# Everything associated with this user, plus all config info, like available plans
		return if @c_billing isnt false
		@c_billing= true
		@c_braintree= {}
		@c_bank_check= {}
		@c_bank_check_prefixed= {}
		rest_results= @rest.get 'User/me/bill_plans', f
		if 'braintree' of rest_results
			(@c_braintree[rec.prefix]= rec) for rec in rest_results.braintree
		if 'bank_check' of rest_results
			(@c_bank_check[rec.id]= rec) for rec in rest_results.bank_check
			(@c_bank_check_prefixed[rec.prefix]= rec) for rec in rest_results.bank_check
		@_getRecommend()
		return
	_getCardInfo: () ->
		f= "M:Billing._getCardInfo"
		return @c_card_info if @c_card_info
		rest_card= @rest.get 'User/me/account', f
		@c_card_info= rest_card.account_details ? {}
	_getHistory: () ->
		f= "M:Billing._getHistory"
		return @c_history if @c_history
		rest= @rest.get 'User/me/History', f
		@c_history= rest.history ? []
	_encryptFields: (plain) ->
		f= "M:Billing._encryptFields"
		_log2 f, 'plain', plain
		braintree= window.Braintree.create window.EpicMvc.Extras.options.BtEncKey
		out=
			cc_exp: braintree.encrypt "#{plain.cc_month}/#{plain.cc_year}"
			cc_num: braintree.encrypt plain.cc_num
			cc_cvv: braintree.encrypt plain.cc_cvv
			cc_name: plain.cc_name, cc_zip: plain.cc_zip
		_log2 f, 'out', out
		out
	_checkCcExp: (issue, oF) -> # Custom validation, check credit-card expiration to be this month or later
		f= 'M:Billing._checkCcExp'
		# Don't bother if these fields already have issues
		f_i= oF.getFieldIssues() # Indexed by html-name
		_log2 f, f_i
		return if 'CcMonth' of f_i or 'CcYear' of f_i
		now= new Date()
		now_y= now.getFullYear()
		y= Number oF.getHtmlFieldValue 'CcYear'
		_log2 f, 'now_y/y', now_y, y
		if y< now_y
			oF.Fb_Make issue, 'CcYear', ['YEAR_IN_PAST']
			return
		now_m= now.getMonth()+ 1
		m= Number oF.getHtmlFieldValue 'CcMonth'
		_log2 f, 'now_m/m', now_m, m
		if y is now_y and m< now_m
			oF.Fb_Make issue, 'CcYear', ['MONTH_YEAR_IN_PAST']
		null

window.EpicMvc.Model.Billing= Billing # Public API
