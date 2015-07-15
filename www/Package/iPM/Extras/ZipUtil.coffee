_log2= -> # TODO 2 REMOVE
#
# Common functions for Zip file creation Crc32, Assemble
#
###
	Blob2Crc32Async= (blob, cb) ->
		reader= new FileReader()
		reader.onerror (evt) ->
			cb evt.target.error
		reader.onload (evt) ->
			data= new Uint8Array evt.target.result
			cb null, ZipUtil.CalcCrc32 data
		reader.readAsArrayBuffer blob
###
# Invoking a download dialogbox w/o user having to do the 'click'
# https://gist.github.com/rudiedirkx/2623261
###
/ **
 * `url` can be a data URI like data: or a blob URI like blob: or an existing, public resource like http:
 * `filename` is the (default) name the file will be downloaded as
 * /
function download( url, filename ) {
	var link = document.createElement('a');
	link.setAttribute('href',url);
	link.setAttribute('download',filename);
	var event = document.createEvent('MouseEvents');
	event.initMouseEvent('click', true, true, window, 1, 0, 0, 0, 0, false, false, false, false, 0, null);
	link.dispatchEvent(event);
}
###
#
# Inspired by <http://stuartk.com/jszip>
# TODO CHECK WITH SHAWN ON NEED TO REFERENCE ANY COPYRIGHTS

class ZipUtil

	@CalcCrc32: (data,prev_crc32) ->
		f= 'E:ZipUtil.CalcCrc32'
		_log2 f, 'data.length', data.length
		prev_crc32?= 0
		(crc32= new Uint32Array 1).set [ prev_crc32^ 0xFFFFFFFF ]
		for i in [0...data.length] # Warning: on large files, this may block the UI
			p= data[ i]^ crc32[ 0]
			crc32[ 0]= @crc32_a[p& 0xFF]^ crc32[ 0]>>> 8
		return crc32[ 0]^ 0xFFFFFFFF

	# A ZIP is the concatenation of:
	# [LocalHdr: PK34, [commonHdr], filename]+ file-contents ...
	# [DirRec  : PK12, version-used, [commonHdr], comment, disk, attrs, file_or_dir, offset, filename ] ...
	# [DirEnd  : PK56, disk-num, num-disks, #entries-on-disk, #-entries-all-disks, size-of-dir, offset-to-dir, comment]
	#
	# Where commonHdr(26) is: [ version-needed, gen-bits, method, time, date, crc32, compressed-size, uncompressed-size, filenme-len, extra-len]
	#
	@P: 'P'.charCodeAt 0
	@K: 'K'.charCodeAt 0
	@_DoList: (list, cb_each_e, cbe_final) => # cb_each_e(item,cbe)
		offset= -1
		doOneE= (err) =>
			offset++
			if err isnt null or offset>= list.length then cbe_final err
			else cb_each_e list[offset], doOneE
		doOneE null
	@Assemble: (writer,files,cb_final) -> # return a blob; files={pathname:,(temp-fs)entry:,crc32:,modified:Date} No 'entry' means directory
		f= 'E:ZipUtil.Assemble'
		_log2 f, 'files.length', files.length
		# Build an array that can be converted to a blob; blobparts can be ArrayBuffers, ArrayViews, blobs, or DOMStrings
		# DOMStrings are converted when stored in a blob as UTF8.
		# DirRecs must all appear at the end of the zip, so build this separatly
		blob_parts= []
		dir_parts= []
		(PK34= new Uint8Array  4).set [ @P, @K, 3, 4]			# Local Hdr magic
		(PK12= new Uint8Array  6).set [ @P, @K, 1, 2, 20, 0]	# DirRec magic + version used DOS/2.0
		(DirF= new Uint8Array 10).set [ # A 'file' entry
			0, 0		# file comment length
			0, 0		# disk number start
			0, 0		# internal file attributes
			0, 0, 0, 0	# external file attributes
		]
		emptyBlob= new Blob [ new Uint8Array 0]
		offset= 0
		dir_len= 0
		counter= 0

		IsErr= (err, who) =>
			return false if err is null
			_log2 who, 'ERROR', err
			return true # Yes there was an error

		# Shared between StartFile & BumpCounters
		commonHdr= false
		nleng= false

		StartFile= (rec,cbe_blob_entry) =>
			_log2 f, 'counter/offset/rec.pathname/entry?size', counter, offset, rec.pathname, if rec.entry then rec.size else 'N'
			nleng= @_getUtf8Len rec.pathname
			if rec.entry
				DirF[ 9]= 0
			else # Directory
				DirF[ 9]= 16
			commonHdr= @_getCommonHdr rec.modified, rec.crc32, rec.size, nleng
			blob_parts.push PK34, commonHdr, rec.pathname
			cbe_blob_entry null, if rec.size is 0 then false else rec.entry

		BumpCounters= (rec) =>
			(offsetBuf= new Uint8Array 4).set [ offset, offset>> 8, offset>> 16, offset>> 24]
			dir_parts.push PK12, commonHdr, DirF, offsetBuf, rec.pathname
			offset+= 30+ nleng+ rec.size # PK34(4)+ commonHdr(26)+ ...
			dir_len+= 46+ nleng # PK12(6)+ commonHdr(26)+ DirF(10)+ offsetBuf(4)+ ...
			counter+= 1

		WriteBlob= (blob,cbe) =>
			ff= f+':WriteBlob'
			_log2 ff, blob.size
			writer.onwriteend= (evt) => cbe null
			writer.onerror=    (evt) => cbe evt.target.error
			writer.write blob

		DoOneFile= (rec,cbe) =>
			ff= f+':DoOneFile'
			_log2 ff, 'rec.size/rec', rec.size, rec
			StartFile rec, (err,entry) =>
				return false if IsErr err, f
				if entry is false
					BumpCounters rec
					return cbe null
				entry.file(
					(file) =>
						blob_parts.push file
						BumpCounters rec
						cbe null
					,(err) => cbe err)

		Finalize= (cbe) =>
			dir_parts.push @_getZipEnd counter, dir_len, offset
			blob_parts.push part for part in dir_parts
			WriteBlob (new Blob blob_parts), =>
				cbe null

		@_DoList files, DoOneFile, (err) =>
			return false if IsErr err, f
			Finalize (err) =>
				return false if IsErr err, f
				cb_final()

	@_getUtf8Len: (str) -> # return size of UTF8
		u= str.length
		for i in [0...str.length]
			c = str.charCodeAt i
			if c> 128
				if c< 2048
					u+= 1
				else
					u+= 2
		return u

	@_getCommonHdr: (date,crc32,dleng,nleng) ->
		dosTime=((( date.getHours()            << 6)| date.getMinutes())  << 5)| date.getSeconds()/ 2
		dosDate=(((( date.getFullYear() - 1980)<< 4)| date.getMonth() + 1)<< 5)| date.getDate()
		hdr= new Uint8Array 26
		hdr.set [
			10, 0										# version needed to extract (dos/1.0)
			0, 8										# general purpose bit flag # set bit 11 if utf8
			0, 0										# compression method
			dosTime, dosTime>> 8						# last mod file time
			dosDate, dosDate>> 8						# last mod file date
			crc32, crc32>> 8, crc32>> 16, crc32>> 24	# crc-32
			dleng, dleng>> 8, dleng>> 16, dleng>> 24	# compressed size
			dleng, dleng>> 8, dleng>> 16, dleng>> 24	# uncompressed size
			nleng, nleng>> 8							# file name length
			0, 0										# extra field length
		]
		hdr

	@_getZipEnd: (numEntries, dirLen, fileLen) ->
		hdr= new Uint8Array 22
		hdr.set [
			@P, @K, 5, 6										# magic:CENTRAL_DIRECTORY_END
			0, 0												# number of this disk
			0, 0												# number of the disk with the start of the central dir
			numEntries, numEntries>> 8							# total number of entries in the central dir on this disk
			numEntries, numEntries>> 8							# total number of entries in the central dir
			dirLen,  dirLen >> 8, dirLen >> 16, dirLen >> 24	# size of the central directory
			fileLen, fileLen>> 8, fileLen>> 16, fileLen>> 24	# offset of start of cent dir wrt start disk num
			0, 0												# .ZIP file comment length
		]
		hdr

	@crc32_a: if window.Uint32Array then new window.Uint32Array 256 else null
	@crc32_t: [
		0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
		0xe963a535, 0x9e6495a3,	0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
		0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
		0xf3b97148, 0x84be41de,	0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
		0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec,	0x14015c4f, 0x63066cd9,
		0xfa0f3d63, 0x8d080df5,	0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
		0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,	0x35b5a8fa, 0x42b2986c,
		0xdbbbc9d6, 0xacbcf940,	0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
		0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
		0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
		0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,	0x76dc4190, 0x01db7106,
		0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
		0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
		0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
		0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
		0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
		0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
		0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
		0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
		0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
		0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
		0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
		0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
		0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
		0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
		0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
		0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
		0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
		0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
		0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
		0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
		0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
		0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
		0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
		0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
		0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
		0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
		0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
		0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
		0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
		0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
		0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
		0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d]
ZipUtil.crc32_a?.set ZipUtil.crc32_t
window.EpicMvc.Extras.ZipUtil= ZipUtil # Public API, singleton

