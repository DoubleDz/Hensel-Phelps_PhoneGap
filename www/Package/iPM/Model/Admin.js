// Generated by CoffeeScript 1.4.0
(function() {
  var Admin,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Admin = (function(_super) {

    __extends(Admin, _super);

    function Admin(Epic, view_nm) {
      var ss;
      ss = {
        state_code: 'CO',
        user_edit: false
      };
      Admin.__super__.constructor.call(this, Epic, view_nm, ss);
      this.rest = window.EpicMvc.Extras.Rest;
      this.sponsor_add_issue = false;
      this.sponsor_add_open = false;
      this.xfer_email = false;
    }

    Admin.prototype.eventNewRequest = function(change) {
      this.Table = {};
      delete this.c_projects;
      if (change.track !== true) {
        return;
      }
      delete this.c_prereg_summary;
      delete this.c_prereg_projects;
      delete this.c_users;
      delete this.c_pstats;
      delete this.braintree_confirm;
      delete this.c_payments;
      return delete this.c_bank_check;
    };

    Admin.prototype.eventLogout = function() {
      return true;
    };

    Admin.prototype.action = function(act, p) {
      var days, dt, expires_date, f, fail, fist, fv, i, id, level_num, m, me, new_level, nm, oF, pay, r, result, stcd, val, _ref, _ref1, _ref2;
      f = "M:Admin.action(" + act + ")";
      _log(f, p);
      r = {};
      i = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      m = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      switch (act) {
        case 'choose_user_edit':
          id = Number(p.id);
          if (this.user_edit !== id) {
            this.user_edit = id;
            this.invalidateTables(['UserEdit']);
          }
          r.success = 'SUCCESS';
          break;
        case 'prereg_state':
          stcd = p.state_code;
          if (this.state_code !== stcd) {
            this.state_code = stcd;
            this.invalidateTables(['PreReg']);
          }
          r.success = 'SUCCESS';
          break;
        case 'bankcheck_clear':
          oF = this.Epic.getFistInstance('AdminUserEditBankcheck');
          oF.clearValues();
          delete this.bankcheck_confirm;
          break;
        case 'onchange_bankcheck':
          oF = this.Epic.getFistInstance('AdminUserEditBankcheck');
          oF.fb_HTML[p.field] = p.value;
          this.invalidateTables(['BcCalc']);
          break;
        case 'user_save_bankcheck_temp':
          oF = this.Epic.getFistInstance('AdminUserEditBankcheck');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          this.bankcheck_confirm = fv;
          r.success = 'SUCCESS';
          break;
        case 'user_save_bankcheck':
          oF = this.Epic.getFistInstance('AdminUserEditBankcheck');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          fv.bill_system = 'bank_check';
          fv.system_total = this.c_last_system_total;
          result = this.rest.post("User/" + this.user_edit + "/purchase", f, fv);
          if (result.SUCCESS === true) {
            delete this.bankcheck_confirm;
            delete this.c_payments;
            _ref = result.updated_user;
            for (nm in _ref) {
              val = _ref[nm];
              this.c_users[this.user_edit][nm] = val;
            }
            if (p.clear) {
              this.user_edit = false;
            }
            this.invalidateTables(true);
            m.add('SUCCESS');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'user_save':
          oF = this.Epic.getFistInstance('AdminUserEdit');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          if (fv.expires.length) {
            fail = false;
            days = Number(fv.expires);
            if (isNaN(days)) {
              try {
                dt = new Date(fv.expires);
              } catch (e) {
                fail = e.message;
              }
            } else {
              dt = new Date();
              dt.setDate(dt.getDate() + days);
            }
            if (isNaN(dt.getMonth())) {
              fail = 'Invalid';
            }
            if (fail !== false) {
              i.add('BAD_DATE', [fail]);
              r.success = 'FAIL';
              return [r, i, m];
            }
            fv.expires = "" + (dt.getMonth() + 1) + "/" + (dt.getDate()) + "/" + (dt.getFullYear());
            me = this.c_users[this.user_edit];
            pay = this._getPayments()[me.bill_system][me.id];
            if (pay) {
              dt = new Date(pay.expires);
              expires_date = "" + (dt.getMonth() + 1) + "/" + (dt.getDate()) + "/" + (dt.getFullYear());
              if (fv.expires === expires_date) {
                fv.expires = '';
              }
            }
          }
          result = this.rest.post("User/" + this.user_edit + "/adminupdate", f, fv);
          if (result.SUCCESS === true) {
            this.invalidateTables(true);
            for (nm in fv) {
              if (nm in this.c_users[this.user_edit]) {
                this.c_users[this.user_edit][nm] = fv[nm];
              }
            }
            if (p.clear) {
              this.user_edit = false;
            }
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'user_save_level':
          oF = this.Epic.getFistInstance('AdminUserEditLevel');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          level_num = fv.level;
          fv.level = (_ref1 = (_ref2 = this.rest.choices().users.level[level_num]) != null ? _ref2.token : void 0) != null ? _ref1 : 'unknown';
          result = this.rest.post("User/" + this.user_edit + "/adminupdatelevel", f, fv);
          if (result.SUCCESS === true) {
            fv.level = level_num;
            for (nm in fv) {
              if (nm in this.c_users[this.user_edit]) {
                this.c_users[this.user_edit][nm] = fv[nm];
              }
            }
            if (p.clear) {
              this.user_edit = false;
            }
            this.invalidateTables(true);
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'user_disable':
          result = this.rest.post("User/" + this.user_edit + "/admindisable", f);
          if (result.SUCCESS === true) {
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'sponsor_del':
          id = Number(p.id);
          result = this.rest.post("Sponsor/" + id + "/remove", f, {
            mask_usid: this.user_edit
          });
          if (result.SUCCESS === true) {
            this.invalidateTables(['Sponsor']);
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'add_sponsor_open':
        case 'add_sponsor_close':
          this.sponsor_add_open = act === 'add_sponsor_open';
          this.sponsor_add_issue = false;
          this.invalidateTables(['SponsorAdd']);
          break;
        case 'sponsor_level':
          new_level = p.as;
          result = this.rest.post("Sponsor/" + p.id + "/updatelevel", f, {
            level: new_level,
            mask_usid: this.user_edit
          });
          if (result.SUCCESS === true) {
            this.invalidateTables(['Sponsor']);
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'sponsor_add':
          oF = this.Epic.getFistInstance('SponsorAddEmail');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          fv.mask_usid = this.user_edit;
          result = this.rest.post("Sponsor/email/add", f, fv);
          if (result.SUCCESS === true) {
            this.invalidateTables(['Sponsor']);
            r.success = 'SUCCESS';
          } else if (result.match(/^"Error: REST_404_USERS/)) {
            this.sponsor_add_issue = fv.email;
            this.invalidateTables(['SponsorAdd']);
            r.success = 'NO_SUCH_USER';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'invite_for_team':
          fist = 'UserInviteForTeam';
          oF = this.Epic.getFistInstance(fist);
          i.call(oF.fieldLevelValidate(p, fist));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          fv.usid = this.user_edit;
          result = this.rest.post('User_invite', f, fv);
          _log2(f, 'result', result);
          if (result.SUCCESS === true) {
            m.add('SENT', [p.email]);
            oF.clearValues();
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'have_email':
          this.xfer_email = p.email;
          r.success = 'SUCCESS';
          break;
        case 'email_test':
          oF = this.Epic.getFistInstance('AdminEmailTest');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.get("Admin_testemail", f, fv);
          if (result.SUCCESS === true) {
            m.add('SUCCESS');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        default:
          return Admin.__super__.action.call(this, act, p);
      }
      return [r, i, m];
    };

    Admin.prototype.loadTable = function(tbl_nm) {
      var curr_projects, d, data, dt, f, h, id, mbytes, mi, mo, new_row, nm, nums, oF, obj, owner, owners, payments, plan, rec, rest_results, results, row, table, time, users, val, vals, y, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _len5, _m, _n, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref23, _ref24, _ref25, _ref26, _ref27, _ref28, _ref29, _ref3, _ref30, _ref31, _ref32, _ref33, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      f = "M:Admin.loadTable(" + tbl_nm + ")";
      switch (tbl_nm) {
        case 'Bankcheck':
          this._getBankCheckPlans();
          table = [];
          _ref = this.c_bank_check;
          for (nm in _ref) {
            row = _ref[nm];
            new_row = $.extend({}, row);
            table.push(new_row);
          }
          this.Table[tbl_nm] = table;
          break;
        case 'Options':
          row = {
            prereg_state: this.state_code,
            prereg_state_nice: (_ref1 = window.state_codes[this.state_code]) != null ? _ref1 : 'empty'
          };
          this.Table[tbl_nm] = [row];
          break;
        case 'UserEdit':
          row = this._getUsers()[this.user_edit];
          results = [];
          new_row = $.extend({}, row);
          new_row.bytes_quota = row.mbytes_quota * 1024 * 1024;
          new_row.level_nice = (_ref2 = (_ref3 = this.rest.choices().users.level[row.level]) != null ? _ref3.nice : void 0) != null ? _ref2 : 'unknown';
          new_row.status_nice = (_ref4 = (_ref5 = this.rest.choices().users.status[row.status]) != null ? _ref5.nice : void 0) != null ? _ref4 : 'unknown';
          new_row.state_nice = (_ref6 = window.state_codes[row.state]) != null ? _ref6 : 'No-state';
          rest_results = this.rest.get("User/" + this.user_edit + "/uploadedmbytes", f);
          mbytes = Number(rest_results.mbytes);
          new_row.mbytes_used = mbytes;
          new_row.bytes_used = mbytes * 1024 * 1024;
          results.push(new_row);
          this.Table[tbl_nm] = results;
          break;
        case 'User':
          this._getPStats();
          users = this._getUsers();
          payments = this._getPayments();
          results = [];
          for (id in users) {
            row = users[id];
            new_row = $.extend({
              expires_days: '',
              is_pending: '',
              is_BT: '',
              BT: [],
              is_BC: '',
              BC: []
            }, row);
            new_row.bytes_quota = row.mbytes_quota * 1024 * 1024;
            new_row.level_nice = (_ref7 = (_ref8 = this.rest.choices().users.level[row.level]) != null ? _ref8.nice : void 0) != null ? _ref7 : 'unknown';
            new_row.level_token = (_ref9 = (_ref10 = this.rest.choices().users.level[row.level]) != null ? _ref10.token : void 0) != null ? _ref9 : 'unknown';
            if (row.status !== 1) {
              new_row.is_pending = 'yes';
            }
            new_row.status_nice = (_ref11 = (_ref12 = this.rest.choices().users.status[row.status]) != null ? _ref12.nice : void 0) != null ? _ref11 : 'unknown';
            new_row.state_nice = (_ref13 = window.state_codes[row.state]) != null ? _ref13 : 'No-state';
            if (row.state == null) {
              new_row.state = '';
            }
            if (row.city == null) {
              new_row.city = '';
            }
            new_row.bill_system_token = (_ref14 = (_ref15 = this.rest.choices().users.bill_system[row.bill_system]) != null ? _ref15.token : void 0) != null ? _ref14 : 'unknown';
            new_row.bill_system_nice = (_ref16 = (_ref17 = this.rest.choices().users.bill_system[row.bill_system]) != null ? _ref17.nice : void 0) != null ? _ref16 : 'Unknown';
            switch (new_row.bill_system) {
              case 1:
                obj = new_row.BT;
                new_row.is_BT = 'yes';
                break;
              case 2:
                obj = new_row.BC;
                new_row.is_BC = 'yes';
            }
            if (row.id in payments[row.bill_system]) {
              obj.push($.extend({}, payments[row.bill_system][row.id]));
              dt = new Date(obj[0].expires);
              obj[0].expires_date = "" + (dt.getMonth() + 1) + "/" + (dt.getDate()) + "/" + (dt.getFullYear());
              obj[0].expires_days = Math.round(((Date.parse(obj[0].expires)) - new Date()) / 86000000);
              if (obj[0].expires_days < 0) {
                obj[0].expires_days = 0;
              }
              new_row.expires_days = obj[0].expires_days;
            }
            if (row.created !== '0000-00-00 00:00:00') {
              time = new Date(row.created);
              y = time.getFullYear();
              mo = ("0" + (time.getMonth() + 1)).slice(-2);
              d = ("0" + time.getDate()).slice(-2);
              h = ("0" + time.getHours()).slice(-2);
              mi = ("0" + time.getMinutes()).slice(-2);
              new_row.created_nice = y + '-' + mo + '-' + d + ' ' + h + ':' + mi;
            } else {
              new_row.created_nice = '---';
            }
            results.push(new_row);
          }
          this.Table[tbl_nm] = results;
          break;
        case 'PreRegSummary':
          data = this._getPreRegSummary();
          results = [];
          _ref18 = data.summary;
          for (_i = 0, _len = _ref18.length; _i < _len; _i++) {
            row = _ref18[_i];
            new_row = $.extend({}, row);
            new_row.status_nice = (_ref19 = (_ref20 = this.rest.choices().invites.status[row.status]) != null ? _ref20.nice : void 0) != null ? _ref19 : 'unknown';
            new_row.state_nice = (_ref21 = window.state_codes[row.state]) != null ? _ref21 : 'No-state';
            results.push(new_row);
          }
          this.Table[tbl_nm] = results;
          break;
        case 'PreReg':
          data = this.rest.get("PreReg/State/" + this.state_code, f);
          results = [];
          _ref22 = data.invites;
          for (_j = 0, _len1 = _ref22.length; _j < _len1; _j++) {
            row = _ref22[_j];
            if (!(row.status === 2)) {
              continue;
            }
            new_row = $.extend({}, row);
            results.push(new_row);
          }
          this.Table[tbl_nm] = results;
          break;
        case 'Owner':
          curr_projects = this._getProjects();
          data = this.rest.get('Project', f);
          owners = {};
          _ref23 = data.owners;
          for (_k = 0, _len2 = _ref23.length; _k < _len2; _k++) {
            rec = _ref23[_k];
            owners[rec.project_id] = rec;
          }
          results = [];
          _ref24 = data.projects;
          for (_l = 0, _len3 = _ref24.length; _l < _len3; _l++) {
            row = _ref24[_l];
            if (!(row.type === 1)) {
              continue;
            }
            owner = (_ref25 = owners[row.id]) != null ? _ref25 : {
              first_name: '',
              last_name: '',
              email: 'NONE'
            };
            new_row = $.extend({}, row, owner, {
              is_watching: ''
            });
            if (row.id in curr_projects) {
              new_row.is_watching = 'yes';
            }
            results.push(new_row);
          }
          results.sort(function(a, b) {
            if (a.name.toLowerCase() === b.name.toLowerCase()) {
              return 0;
            } else if (a.name.toLowerCase() > b.name.toLowerCase()) {
              return 1;
            } else {
              return -1;
            }
          });
          this.Table[tbl_nm] = results;
          break;
        case 'Sponsor':
          rest_results = this.rest.get("Sponsor", f, {
            mask_usid: this.user_edit
          });
          results = [];
          _ref27 = (_ref26 = rest_results.sponsors) != null ? _ref26 : [];
          for (_m = 0, _len4 = _ref27.length; _m < _len4; _m++) {
            row = _ref27[_m];
            new_row = $.extend({}, row);
            new_row.level_nice = (_ref28 = (_ref29 = this.rest.choices().users.level[row.level]) != null ? _ref29.nice : void 0) != null ? _ref28 : '?';
            new_row.level_token = (_ref30 = (_ref31 = this.rest.choices().users.level[row.level]) != null ? _ref31.token : void 0) != null ? _ref30 : '?';
            results.push(new_row);
          }
          this.Table[tbl_nm] = results;
          break;
        case 'SponsorAdd':
          table = [];
          table.push({
            issue: this.sponsor_add_issue === false ? '' : 'yes',
            issue_email: this.sponsor_add_issue,
            open: this.sponsor_add_open === true ? 'yes' : ''
          });
          this.Table[tbl_nm] = table;
          break;
        case 'BcCalc':
          this.Table[tbl_nm] = [
            {
              is_valid: ''
            }
          ];
          oF = this.Epic.getFistInstance('AdminUserEditBankcheck');
          oF.Fb_Html2Db('AdminUserEditBankcheck');
          vals = oF.getDbFieldValues();
          nums = {};
          for (nm in vals) {
            val = vals[nm];
            nums[nm] = (_ref32 = Number(val)) != null ? _ref32 : 0;
          }
          plan = false;
          _ref33 = this.Epic.getViewTable('Billing/Bankcheck');
          for (_n = 0, _len5 = _ref33.length; _n < _len5; _n++) {
            rec = _ref33[_n];
            if (rec.id === Number(nums.plan_id)) {
              plan = rec;
              break;
            }
          }
          if (plan === false) {
            return;
          }
          row = $.extend({
            total_spships: 0,
            total_gblock: 0,
            total_month: 0,
            total_check: 0,
            total_total: 0,
            total_discount: 0,
            discount_pct: 0
          }, plan, nums);
          row.total_spships = row.spship_price * row.extra_spships;
          row.total_gblock = row.gblock_price * row.extra_gblocks;
          row.total_month = row.base_price + row.total_spships + row.total_gblock;
          if (row.months) {
            row.total_total = row.total_month * row.months;
          }
          row.total_check = row.check_total;
          if (row.check_total) {
            row.total_discount = row.total_total - row.total_check;
            row.discount_pct = (row.total_discount / row.total_total * 100).toFixed(1);
          }
          row.is_valid = 'yes';
          this.c_last_system_total = row.total_total;
          this.Table[tbl_nm] = [row];
          break;
        default:
          Admin.__super__.loadTable.call(this, tbl_nm);
      }
    };

    Admin.prototype._getPreRegSummary = function() {
      var f;
      f = "M:Admin._getPreRegSummary";
      if (this.c_prereg_summary) {
        return this.c_prereg_summary;
      }
      return this.c_prereg_summary = this.rest.get('PreReg/State', f);
    };

    Admin.prototype._getProjects = function() {
      var f;
      f = "M:Admin._getProjects";
      if (this.c_projects) {
        return this.c_projects;
      }
      return this.c_projects = (this.Epic.getInstance('Directory')).getActiveProjectList();
    };

    Admin.prototype._getUsers = function() {
      var f, rec, results, _i, _len, _ref;
      f = "M:Admin._getUsers";
      if (this.c_users) {
        return this.c_users;
      }
      results = this.rest.get('User', f);
      if (!('users' in results)) {
        return {};
      }
      this.c_users = {};
      _ref = results.users;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rec = _ref[_i];
        this.c_users[rec.id] = rec;
      }
      return this.c_users;
    };

    Admin.prototype._getPayments = function() {
      var f, rec, results, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;
      f = "M:Admin._getPaments";
      if (this.c_payments) {
        return this.c_payments;
      }
      results = this.rest.get('User_payment', f);
      this.c_payments = [{}, {}, {}];
      _ref1 = (_ref = results.braintree) != null ? _ref : [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        rec = _ref1[_i];
        this.c_payments[1][rec.user_id] = rec;
      }
      _ref3 = (_ref2 = results.bank_check) != null ? _ref2 : [];
      for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
        rec = _ref3[_j];
        this.c_payments[2][rec.user_id] = rec;
      }
      return this.c_payments;
    };

    Admin.prototype._getPStats = function() {
      var child, cnt_projects, count, f, map, nm, parent, results, row, sub_cnt_children, sub_cnt_parents, user_id, val, _i, _j, _k, _l, _len, _len1, _len2, _len3, _name, _name1, _name2, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
      f = "M:Admin._getPStats";
      if (this.c_pstats) {
        return this.c_pstats;
      }
      this._getUsers();
      results = this.rest.get('User_pstats', f);
      map = {
        '30:30': 'cnt_watch',
        '30:1': 'cnt_watch_demoted',
        '30:0': 'cnt_watch_restricted',
        '20:20': 'cnt_owner',
        '20:1': 'cnt_owner_demoted',
        '20:0': 'cnt_owner_restricted',
        '20:10': 'cnt_owner_demoted',
        '10:10': 'cnt_manager',
        '10:1': 'cnt_manager_demoted',
        '10:0': 'cnt_manager_restricted',
        '0:2': 'cnt_member_plus',
        '0:1': 'cnt_member',
        '0:0': 'cnt_member_restricted',
        'what?': 'what?'
      };
      _ref = this.c_users;
      for (user_id in _ref) {
        row = _ref[user_id];
        $.extend(row, {
          cnt_projects_owned: '',
          sub_parent: '',
          sub_cnt_children: '',
          sub_children: '',
          inv_who: '',
          inv_who_email: '',
          inv_cnt: 0
        });
        for (nm in map) {
          val = map[nm];
          row[val] = '';
        }
      }
      cnt_projects = {};
      _ref1 = results.user_owned_projects;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        row = _ref1[_i];
        if ((_ref2 = cnt_projects[_name = row.user_id]) == null) {
          cnt_projects[_name] = 0;
        }
        cnt_projects[row.user_id]++;
      }
      sub_cnt_children = {};
      sub_cnt_parents = {};
      _ref3 = results.sponsorships;
      for (_j = 0, _len1 = _ref3.length; _j < _len1; _j++) {
        row = _ref3[_j];
        if ((_ref4 = sub_cnt_children[_name1 = row.parent_user_id]) == null) {
          sub_cnt_children[_name1] = [];
        }
        sub_cnt_children[row.parent_user_id].push(row.child_user_id);
        if ((_ref5 = sub_cnt_parents[_name2 = row.child_user_id]) == null) {
          sub_cnt_parents[_name2] = [];
        }
        sub_cnt_parents[row.child_user_id].push(row.parent_user_id);
      }
      for (user_id in cnt_projects) {
        count = cnt_projects[user_id];
        this.c_users[user_id].cnt_projects_owned = count;
      }
      _ref6 = results.user_memberships;
      for (_k = 0, _len2 = _ref6.length; _k < _len2; _k++) {
        row = _ref6[_k];
        this.c_users[row.user_id][(_ref7 = map[row.invited_as + ':' + row["class"]]) != null ? _ref7 : 'what?'] = row.count;
      }
      for (child in sub_cnt_parents) {
        row = sub_cnt_parents[child];
        this.c_users[child].sub_parent = row.join(',');
      }
      for (parent in sub_cnt_children) {
        row = sub_cnt_children[parent];
        this.c_users[parent].sub_cnt_children = row.length;
        this.c_users[parent].sub_children = row.join('~');
      }
      _ref8 = results.invites;
      for (_l = 0, _len3 = _ref8.length; _l < _len3; _l++) {
        row = _ref8[_l];
        this.c_users[row.usid].inv_who = row.susid;
        this.c_users[row.usid].inv_who_email = this.c_users[row.susid].email;
        this.c_users[row.susid].inv_cnt++;
      }
      return this.c_pstats = results;
    };

    Admin.prototype._getBankCheckPlans = function() {
      var f, rec, rest_results, _i, _len, _ref, _results;
      f = "M:Admin._getBankCheckPlans";
      if (this.c_bank_check) {
        return this.c_bank_check;
      }
      this.c_bank_check = {};
      rest_results = this.rest.get('User/me/bill_plans', f);
      if ('bank_check' in rest_results) {
        _ref = rest_results.bank_check;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rec = _ref[_i];
          _results.push(this.c_bank_check[rec.id] = rec);
        }
        return _results;
      }
    };

    Admin.prototype.fistLoadData = function(oFist) {
      var dt, email, expires_date, f, me, pay, pro;
      f = "M:Admin.fistLoadData(" + (oFist.getFistNm()) + ")";
      switch (oFist.getFistNm()) {
        case 'AdminUserEdit':
        case 'AdminUserEditLevel':
          me = this._getUsers()[this.user_edit];
          oFist.setFromDbValues(this._getUsers()[this.user_edit]);
          pay = this._getPayments()[me.bill_system][me.id];
          if (pay) {
            dt = new Date(pay.expires);
            expires_date = "" + (dt.getMonth() + 1) + "/" + (dt.getDate()) + "/" + (dt.getFullYear());
            return oFist.setFromDbValues({
              expires: expires_date
            });
          }
          break;
        case 'AdminUserEditBankcheck':
          if (this.bankcheck_confirm) {
            return oFist.setFromDbValues(this.bankcheck_confirm);
          } else if (this.c_users[this.user_edit].bill_system === 2) {
            return oFist.setFromDbValues(this.c_payments[2][this.user_edit]);
          } else {
            return oFist.setFromDbValues({
              plan_id: 1,
              extra_spships: 0,
              extra_gblocks: 0,
              months: 1,
              check_total: 0
            });
          }
          break;
        case 'UserInviteForTeam':
          pro = this._getUsers()[this.user_edit];
          if (this.xfer_email !== false) {
            email = this.xfer_email;
            this.xfer_email = false;
          } else {
            email = '';
          }
          return oFist.setFromDbValues({
            msg: "" + pro.first_name + " " + pro.last_name + " wants to invite you to join iProjectMobile.",
            email: email
          });
        case 'AdminEmailTest':
          return null;
        default:
          return Admin.__super__.fistLoadData.call(this, oFist);
      }
    };

    Admin.prototype.fistGetFieldChoices = function(oFist, field) {
      var f, fdef, nm, options, rec, results, val, values, _i, _j, _len, _len1, _ref, _ref1, _results;
      f = 'M:Folder.fistGetFieldChoices:' + oFist.getFistNm() + ':' + field;
      _log2(f, oFist);
      switch (field) {
        case 'Level':
          results = (function() {
            var _ref, _results;
            _ref = this.rest.choices().users.level;
            _results = [];
            for (nm in _ref) {
              val = _ref[nm];
              _results.push([val.sort, val.nice, nm]);
            }
            return _results;
          }).call(this);
          results.sort(function(a, b) {
            return a[0] - b[0];
          });
          return {
            options: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = results.length; _i < _len; _i++) {
                rec = results[_i];
                _results.push(rec[1]);
              }
              return _results;
            })(),
            values: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = results.length; _i < _len; _i++) {
                rec = results[_i];
                _results.push(rec[2]);
              }
              return _results;
            })()
          };
        case 'PreRegState':
          options = [];
          values = [];
          _ref = this._getPreRegSummary();
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            rec = _ref[_i];
            if (!(rec.status === 2)) {
              continue;
            }
            options.push(window.state_codes[rec.state] + (" (" + rec.count + ")"));
            _results.push(values.push(rec.state));
          }
          return _results;
          break;
        case 'BcPlanChoice':
          options = [];
          values = [];
          fdef = oFist.getFieldAttributes(field);
          if ('choice' in fdef) {
            options.push(fdef.choice);
            values.push('');
          }
          _ref1 = this.Epic.getViewTable('Billing/Bankcheck');
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            rec = _ref1[_j];
            options.push(rec.plan_name);
            values.push(String(rec.id));
          }
          _log2(f, {
            options: options,
            values: values
          });
          return {
            options: options,
            values: values
          };
        default:
          return Admin.__super__.fistGetFieldChoices.call(this, oFist, field);
      }
    };

    return Admin;

  })(window.EpicMvc.ModelJS);

  window.EpicMvc.Model.Admin = Admin;

}).call(this);
