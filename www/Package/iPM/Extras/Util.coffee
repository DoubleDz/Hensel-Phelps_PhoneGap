
bytesToSize= (bytes, sizes) ->
	sizes?= ['B', 'KB', 'MB', 'GB', 'TB']
	ix = 0
	while ix< sizes.length- 1 and bytes >= 1024
		ix+= 1
		bytes/= 1024
	bytes.toFixed(1) + sizes[ix]

extToIconPostfix= (file, ext) ->
	file_types = ['pdf','doc','docx','ppt','pptx','xls','xlsx','jpg','jpeg','gif','png','mp3','mp4','m4v','mov','bmp','dwg','wav','svg']
	ext= (file.split '.').pop() if not ext or ext.length is 0
	ext= ext.toLowerCase()
	return if (file_types.indexOf ext) isnt -1 then ext else 'unknown'

custom_filter= (val,spec) ->
	f= 'filter'
	#_log2 f, val, spec
	[func,p1,p2,p3]= spec.split ':'
	switch func
		when 'date'
			[y,m,d]= ( val.split 'T')[0].split '-'
			if p1 is 'long'
				mmap= ['0', 'January', 'February', 'March', 'April', 'May', 'June',
					'July', 'August', 'September', 'October', 'November', 'December']
				"#{mmap[ Number m]} #{d}, #{y}"
			else "#{m}/#{d}/#{y}"
		when 'to_upper'
			val.toUpperCase()
		when 'clean_to_lower'
			val= val.replace(' ', '_')
			val.toLowerCase()
		when 'cents'
			((Number val) / 100).toFixed 2
		when 'dollars'
			((Number val) / 100).toFixed 0
		when 'money'
			val= String val
			[d,c]= val.split '.'; c?= ''
			c= if c.length is 0 then '00' else if c.length is 1 then c+ '0' else c.substr(0,2)
			d= if d.length is 0 then '0' else d
			return "<span class='dollars'>#{d}</span>.<span class='cents'>#{c}</span>"
		when 'trunc'
			if val.indexOf('.') is -1
				ext = ""
			else
				ext = val.substring(val.lastIndexOf(".") + 1, val.length).toLowerCase()
			filename = val.replace('.' + ext, '')
			if filename.length <= p1
				return val
			else
				filename = filename.substr(0, p1)
				filename += '..' if val.length > p1
				return filename + '.' + ext
		else undefined

CHECK_ipm_password= (fieldName, validateExpr, value, oF) ->
	# Require 6 chars and 1 number...also special chars allowed !@#$%^&* for backward compatibility
	# (?=.*[0-9]+) => the chain must have 1+ numbers
	# (?=.*[a-zA-Z]) => the chain must contain alpha numeric letters
	# [0-9a-zA-Z!@#$%^&*]{6,} => the chain can only contain number, alpha, and the special characters !@#$%^&* and must be >6 length
	patt1=new RegExp("^(?=.*[0-9]+)(?=.*[a-zA-Z])[0-9a-zA-Z!@#$%^&*]{6,}$")
	return patt1.test(value)

CHECK_ccnum= (fieldName, validateExpr, value, oF) ->
	length_pat= new RegExp "^[0-9]{13,16}$" # Also validates as only digits
	length_valid= length_pat.test value
	return false unless length_valid
	# Luhn test
	odd= value.length% 2
	a= 0
	for i in [0...value.length]
		v= Number value[ i]
		v+= v+ Math.floor (v * 2)/ 10 unless (odd+ i)% 2
		a+= v
	a% 10 is 0

CHECK_number= (fieldName, validateExpr, value, oF) ->
	patt=new RegExp("^[0-9]+$")
	return patt.test(value)

CHECK_money= (fieldName, validateExpr, value, oF) ->
	patt=new RegExp("^[0-9]+[.][0-9]{2}$")
	return patt.test(value)

H2H_prefilter= (fieldName, spec, value) ->
	value.replace /[<>]/g, '-' if typeof value is 'string'
	value

H2D_money= (fieldName, filtExpr, value) ->
	((parseFloat value) * 100).toFixed 0

D2H_money= (fieldName, filtExpr, value) ->
	return value if typeof value is 'string' and value.length is 0
	str= (Number value) / 100
	str.toFixed 2

make_date= (date_obj) ->
	sep= '/'
	return ( date_obj.getMonth()+ 1)+ sep+ date_obj.getDate()+ sep+ date_obj.getFullYear()

make_time= (date_obj) ->
	sep= ':'
	h= date_obj.getHours()
	ap= [' am',' pm'][if h< 12 then 0 else 1]
	h= if h is 0 then 12 else if h> 12 then h- 12 else h
	min= if date_obj.getMinutes()<10 then  '0' + date_obj.getMinutes() else date_obj.getMinutes()
	return h+ sep+ min + ap

state_codes=
	AL: 'Alabama', AK: 'Alaska', AZ: 'Arizona', AR: 'Arkansas', CA: 'California', CO: 'Colorado',
	CT: 'Connecticut', DE: 'Delaware', DC: 'District of Columbia', FL: 'Florida', GA: 'Georgia',
	HI: 'Hawaii', ID: 'Idaho', IL: 'Illinois', IN: 'Indiana', IA: 'Iowa', KS: 'Kansas', KY: 'Kentucky',
	LA: 'Louisiana', ME: 'Maine', MD: 'Maryland', MA: 'Massachusetts', MI: 'Michigan', MN: 'Minnesota',
	MO: 'Missouri', MT: 'Montana', NE: 'Nebraska', NV: 'Nevada', NH: 'New Hampshire', NJ: 'New Jersey',
	NM: 'New Mexico', NY: 'New York', NC: 'North Carolina', ND: 'North Dakota', OH: 'Ohio',
	OK: 'Oklahoma', OR: 'Oregon', PA: 'Pennsylvania', RI: 'Rhode Island', SC: 'South Carolina',
	SD: 'South Dakota', TN: 'Tennessee', TX: 'Texas', UT: 'Utah', VT: 'Vermont', VA: 'Virginia',
	WA: 'Washington', WV: 'West Virginia', WI: 'Wisconsin', WY: 'Wyoming'


state_codes_sort= [
	'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID','IL','IN','IA',
	'KS','KY','LA','ME','MD','MA','MI','MN','MO','MT','NE','NV','NH','NJ','NM','NY',
	'NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY']

char_filter= (str) ->
	rows= $ '.char-filter'
	if str.length is 0
		rows.show()
		return
	pat= new RegExp str,'i'
	rows.each ()->
		e= $ @
		parts= e.attr 'data-chars'
		if (parts.search pat) isnt -1
			e.show()
		else
			e.hide()

window.bytesToSize= bytesToSize # Global API
window.extToIconPostfix= extToIconPostfix  # Global API
window.EpicMvc.custom_filter= custom_filter # For &Table/column##filter-spec; processing
# Custom Fist check functions
window.EpicMvc.FistFilt.CHECK_ipm_password= CHECK_ipm_password
window.EpicMvc.FistFilt.CHECK_number= CHECK_number
window.EpicMvc.FistFilt.CHECK_money= CHECK_money
window.EpicMvc.FistFilt.CHECK_ccnum= CHECK_ccnum
window.EpicMvc.FistFilt.H2H_prefilter= H2H_prefilter # Custom Fist html2html function
window.EpicMvc.FistFilt.H2D_money= H2D_money # Custom Fist html2db function
window.EpicMvc.FistFilt.D2H_money= D2H_money # Custom Fist db2html function
window.make_date= make_date # Global API
window.make_time= make_time # Global API
window.state_codes= state_codes # Global API
window.state_codes_sort= state_codes_sort # Global API
window.char_filter= char_filter # Global API
