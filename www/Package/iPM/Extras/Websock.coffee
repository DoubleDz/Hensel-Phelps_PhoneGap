
# A cheap REST Long-poll method

class Poll
	constructor: (@endpoint,@cursor,@cb) ->
		f= 'Poll::constructor'
		#_log2 f
		@resource= 'Poll'
		@retry= 500
		@retry_max= 30000
		@xhr= false
		@pending= false # A setTimeout is going?
		@abort= false # True to suspend all activity
	Stop: ->
		f= 'E:Poll.Stop'
		_log2 f, pending: @pending, (if @xhr then 'running' else 'not-running')
		@abort= true # Before xhr.abort() to signal to not try again
		(clearTimeout @pending; @pending= false) if @pending isnt false
		(@xhr.abort(); @xhr= false) if @xhr isnt false
	Start: (delay) =>
		f= 'Poll::Start'
		#_log2 f, delay or 'no-delay', @cursor or 'no@cursor', (if @xhr then 'running' else 'not-running'), if @pending then 'pending' else 'not-pending'
		(@abort= false; delay= @retry) if delay is true # Special case, un-suspend activity
		return if @pending isnt false or @xhr isnt false or @abort is true
		delay?= @retry
		delay = @retry_max if delay> @retry_max
		data_obj= cursors: @cursor
		options=
			cache: false, async: true, timeout: 0, type: 'post'
			dataType: 'json', data: JSON.stringify data_obj
			#TODO SETTING CONTENT-TYPE TO JSON CAUSES PRE_FLIGHT, NEED TO SIMULATE IT IN RESTIFY?
			#contentType: 'application/json'
			url: @endpoint+ @resource
			# Proxy option on url does not work with token-as-var option below
			#url: 'http://epic.dv-mobile.com/proxy_cors.php?url='+ encodeURIComponent( @endpoint+ @resource)
			success: (data) =>
				@xhr= false
				#_log f, ' data=', data
				return if @abort is true
				again= @cb data
				@cursor= data.cursors if data.cursors?
				@Start() if again
				return
			error: (jqXHR, textStatus, errorThrown) =>
				@xhr= false
				#_log f, ' delay=', delay
				_log f, ' AJAX ERROR', jq:jqXHR, ts:textStatus, et:errorThrown
				return if @abort is true
				if errorThrown is 'Unauthorized' then window.EpicMvc.Extras.Rest.doToken()
				@Start delay* 2 # Back off exponentially
				return
		@pending= setTimeout =>
			#_log2 f, '::setTimeout', options.data
			@pending= false
			return if @abort is true
			# Get the very latest token availble
			token= window.EpicMvc.Extras.Rest.token
			return if token is false # Logged out, I guess?
			#options.headers= Authorization: "#{token.token_type} #{token.access_token}"
			# Note: to enable auth_token, you should also comment out 'contentType' above
			options.url+= '?auth_token='+ encodeURIComponent "#{token.access_token}"
			@xhr= $.ajax options
		, delay
		return

window.EpicMvc.Extras.Poll= Poll # Public API
