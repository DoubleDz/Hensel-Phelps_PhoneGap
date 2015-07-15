# Open an S3 file signed URL for either 'inline' or 'download'
# Use:
#   <a href="#" onclick="S3Open( &File/prid;, &File/ix;);return false;">&File/name;</a>

S3Open= (prid,fiix,inline,use_version_name) ->
	cmd= window.EpicMvc.Extras.Rest
	i_or_a= if inline then 'inline' else 'attachment'
	i_or_a+= '_version' if use_version_name is true
	response= cmd.rest "/Project/#{prid}/File/#{fiix}/#{i_or_a}", 'S3Open()'
	if not ('signed_url' of response)
		alert 'S3Open() bad response: '+ JSON.stringify response
		return
	url= response.signed_url
	if inline then window.open url, '_blank' else window.location.assign url
	#window.open url, if inline then '_blank' else 'Download'
	return

window.S3Open= S3Open
