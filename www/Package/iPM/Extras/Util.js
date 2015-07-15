// Generated by CoffeeScript 1.4.0
(function() {
  var CHECK_ccnum, CHECK_ipm_password, CHECK_money, CHECK_number, D2H_money, H2D_money, H2H_prefilter, bytesToSize, char_filter, custom_filter, extToIconPostfix, make_date, make_time, state_codes, state_codes_sort;

  bytesToSize = function(bytes, sizes) {
    var ix;
    if (sizes == null) {
      sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    }
    ix = 0;
    while (ix < sizes.length - 1 && bytes >= 1024) {
      ix += 1;
      bytes /= 1024;
    }
    return bytes.toFixed(1) + sizes[ix];
  };

  extToIconPostfix = function(file, ext) {
    var file_types;
    file_types = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'jpg', 'jpeg', 'gif', 'png', 'mp3', 'mp4', 'm4v', 'mov', 'bmp', 'dwg', 'wav', 'svg'];
    if (!ext || ext.length === 0) {
      ext = (file.split('.')).pop();
    }
    ext = ext.toLowerCase();
    if ((file_types.indexOf(ext)) !== -1) {
      return ext;
    } else {
      return 'unknown';
    }
  };

  custom_filter = function(val, spec) {
    var c, d, ext, f, filename, func, m, mmap, p1, p2, p3, y, _ref, _ref1, _ref2;
    f = 'filter';
    _ref = spec.split(':'), func = _ref[0], p1 = _ref[1], p2 = _ref[2], p3 = _ref[3];
    switch (func) {
      case 'date':
        _ref1 = (val.split('T'))[0].split('-'), y = _ref1[0], m = _ref1[1], d = _ref1[2];
        if (p1 === 'long') {
          mmap = ['0', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
          return "" + mmap[Number(m)] + " " + d + ", " + y;
        } else {
          return "" + m + "/" + d + "/" + y;
        }
        break;
      case 'to_upper':
        return val.toUpperCase();
      case 'clean_to_lower':
        val = val.replace(' ', '_');
        return val.toLowerCase();
      case 'cents':
        return ((Number(val)) / 100).toFixed(2);
      case 'dollars':
        return ((Number(val)) / 100).toFixed(0);
      case 'money':
        val = String(val);
        _ref2 = val.split('.'), d = _ref2[0], c = _ref2[1];
        if (c == null) {
          c = '';
        }
        c = c.length === 0 ? '00' : c.length === 1 ? c + '0' : c.substr(0, 2);
        d = d.length === 0 ? '0' : d;
        return "<span class='dollars'>" + d + "</span>.<span class='cents'>" + c + "</span>";
      case 'trunc':
        if (val.indexOf('.') === -1) {
          ext = "";
        } else {
          ext = val.substring(val.lastIndexOf(".") + 1, val.length).toLowerCase();
        }
        filename = val.replace('.' + ext, '');
        if (filename.length <= p1) {
          return val;
        } else {
          filename = filename.substr(0, p1);
          if (val.length > p1) {
            filename += '..';
          }
          return filename + '.' + ext;
        }
        break;
      default:
        return void 0;
    }
  };

  CHECK_ipm_password = function(fieldName, validateExpr, value, oF) {
    var patt1;
    patt1 = new RegExp("^(?=.*[0-9]+)(?=.*[a-zA-Z])[0-9a-zA-Z!@#$%^&*]{6,}$");
    return patt1.test(value);
  };

  CHECK_ccnum = function(fieldName, validateExpr, value, oF) {
    var a, i, length_pat, length_valid, odd, v, _i, _ref;
    length_pat = new RegExp("^[0-9]{13,16}$");
    length_valid = length_pat.test(value);
    if (!length_valid) {
      return false;
    }
    odd = value.length % 2;
    a = 0;
    for (i = _i = 0, _ref = value.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      v = Number(value[i]);
      if (!((odd + i) % 2)) {
        v += v + Math.floor((v * 2) / 10);
      }
      a += v;
    }
    return a % 10 === 0;
  };

  CHECK_number = function(fieldName, validateExpr, value, oF) {
    var patt;
    patt = new RegExp("^[0-9]+$");
    return patt.test(value);
  };

  CHECK_money = function(fieldName, validateExpr, value, oF) {
    var patt;
    patt = new RegExp("^[0-9]+[.][0-9]{2}$");
    return patt.test(value);
  };

  H2H_prefilter = function(fieldName, spec, value) {
    if (typeof value === 'string') {
      value.replace(/[<>]/g, '-');
    }
    return value;
  };

  H2D_money = function(fieldName, filtExpr, value) {
    return ((parseFloat(value)) * 100).toFixed(0);
  };

  D2H_money = function(fieldName, filtExpr, value) {
    var str;
    if (typeof value === 'string' && value.length === 0) {
      return value;
    }
    str = (Number(value)) / 100;
    return str.toFixed(2);
  };

  make_date = function(date_obj) {
    var sep;
    sep = '/';
    return (date_obj.getMonth() + 1) + sep + date_obj.getDate() + sep + date_obj.getFullYear();
  };

  make_time = function(date_obj) {
    var ap, h, min, sep;
    sep = ':';
    h = date_obj.getHours();
    ap = [' am', ' pm'][h < 12 ? 0 : 1];
    h = h === 0 ? 12 : h > 12 ? h - 12 : h;
    min = date_obj.getMinutes() < 10 ? '0' + date_obj.getMinutes() : date_obj.getMinutes();
    return h + sep + min + ap;
  };

  state_codes = {
    AL: 'Alabama',
    AK: 'Alaska',
    AZ: 'Arizona',
    AR: 'Arkansas',
    CA: 'California',
    CO: 'Colorado',
    CT: 'Connecticut',
    DE: 'Delaware',
    DC: 'District of Columbia',
    FL: 'Florida',
    GA: 'Georgia',
    HI: 'Hawaii',
    ID: 'Idaho',
    IL: 'Illinois',
    IN: 'Indiana',
    IA: 'Iowa',
    KS: 'Kansas',
    KY: 'Kentucky',
    LA: 'Louisiana',
    ME: 'Maine',
    MD: 'Maryland',
    MA: 'Massachusetts',
    MI: 'Michigan',
    MN: 'Minnesota',
    MO: 'Missouri',
    MT: 'Montana',
    NE: 'Nebraska',
    NV: 'Nevada',
    NH: 'New Hampshire',
    NJ: 'New Jersey',
    NM: 'New Mexico',
    NY: 'New York',
    NC: 'North Carolina',
    ND: 'North Dakota',
    OH: 'Ohio',
    OK: 'Oklahoma',
    OR: 'Oregon',
    PA: 'Pennsylvania',
    RI: 'Rhode Island',
    SC: 'South Carolina',
    SD: 'South Dakota',
    TN: 'Tennessee',
    TX: 'Texas',
    UT: 'Utah',
    VT: 'Vermont',
    VA: 'Virginia',
    WA: 'Washington',
    WV: 'West Virginia',
    WI: 'Wisconsin',
    WY: 'Wyoming'
  };

  state_codes_sort = ['AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'];

  char_filter = function(str) {
    var pat, rows;
    rows = $('.char-filter');
    if (str.length === 0) {
      rows.show();
      return;
    }
    pat = new RegExp(str, 'i');
    return rows.each(function() {
      var e, parts;
      e = $(this);
      parts = e.attr('data-chars');
      if ((parts.search(pat)) !== -1) {
        return e.show();
      } else {
        return e.hide();
      }
    });
  };

  window.bytesToSize = bytesToSize;

  window.extToIconPostfix = extToIconPostfix;

  window.EpicMvc.custom_filter = custom_filter;

  window.EpicMvc.FistFilt.CHECK_ipm_password = CHECK_ipm_password;

  window.EpicMvc.FistFilt.CHECK_number = CHECK_number;

  window.EpicMvc.FistFilt.CHECK_money = CHECK_money;

  window.EpicMvc.FistFilt.CHECK_ccnum = CHECK_ccnum;

  window.EpicMvc.FistFilt.H2H_prefilter = H2H_prefilter;

  window.EpicMvc.FistFilt.H2D_money = H2D_money;

  window.EpicMvc.FistFilt.D2H_money = D2H_money;

  window.make_date = make_date;

  window.make_time = make_time;

  window.state_codes = state_codes;

  window.state_codes_sort = state_codes_sort;

  window.char_filter = char_filter;

}).call(this);
