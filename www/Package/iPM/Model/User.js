// Generated by CoffeeScript 1.4.0
(function() {
  var User,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  User = (function(_super) {

    __extends(User, _super);

    function User(Epic, view_nm) {
      this.UpdateUserAsync = __bind(this.UpdateUserAsync, this);

      var ss;
      ss = {
        invite_code: false,
        tab_home: 'clear'
      };
      User.__super__.constructor.call(this, Epic, view_nm, ss);
      this.rest = window.EpicMvc.Extras.Rest;
      this.invite_rec = false;
      this.xfer_email = false;
      this.xfer_project = false;
      this.xfer_details = {};
      this.invite_display = {};
      this.login_msg = false;
    }

    User.prototype.eventLogout = function() {
      return true;
    };

    User.prototype.eventNewRequest = function(change) {
      delete this.Table.DynaInfo;
      if (change.track !== true) {
        return;
      }
      delete this.c_myself;
      return this.invalidateTables(['Me']);
    };

    User.prototype.action = function(act, p) {
      var endpoint, f, fist, flist, fv, i, m, mExtern, oF, options, prid, projects, r, rec, result, tab, valid, _ref, _ref1, _ref2, _ref3, _ref4;
      f = "M:User::action(" + act + ")";
      _log(f, p);
      r = {};
      i = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      m = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      switch (act) {
        case 'url_invite':
          r.url = 'signup_confirm-' + this.invite_code;
          break;
        case 'url_invite_team':
          r.url = 'team_invite-' + this.invite_code;
          break;
        case 'check':
          if ((valid = this.rest.doToken()) !== false) {
            r.valid = 'yes';
            options = this.Epic.getViewTable('Directory/Options');
            if (options[0].cache_pending === 'yes') {
              r.loading = 'yes';
            } else {
              projects = this.Epic.getViewTable('Directory/Member');
              r.projects = (projects.length ? 'yes' : 'no');
            }
          } else {
            r = {
              valid: 'no'
            };
          }
          break;
        case 'login':
          delete this.Table.Me;
          oF = this.Epic.getFistInstance('Login');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.login(fv.email, fv.password);
          if (result !== false) {
            projects = this.Epic.getViewTable('Directory/Member');
            this.Epic.login();
            rec = this._getMyself();
            if (rec.is_recommendation === true) {
              this.login_msg = true;
            }
            this.invalidateTables(['LoginMsg']);
            r = {
              success: 'SUCCESS',
              projects: (projects.length ? 'yes' : 'no')
            };
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'clear_login_msg':
          this.login_msg = false;
          this.invalidateTables(['LoginMsg']);
          break;
        case 'logout':
          this.login_msg = false;
          this.invalidateTables(['LoginMsg']);
          this.rest.logout();
          this.Epic.logout();
          break;
        case 'have_email':
          this.xfer_email = p.email;
          this.xfer_project = p.project;
          r.success = 'SUCCESS';
          break;
        case 'forgot_xfer':
          this.forgot_xfer_pswd = p.AuthEmail;
          r.success = 'SUCCESS';
          break;
        case 'send_forgot':
          oF = this.Epic.getFistInstance('UserForgot');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.post('User_forgot', f, fv);
          _log2(f, 'result', result);
          if (result.SUCCESS === true) {
            m.add('EMAIL_SENT', [fv.email]);
            r = {
              success: 'SUCCESS'
            };
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'choose_user':
          if (this.userid !== p.id) {
            this.userid = p.id;
            delete this.Table.User;
          }
          r.success = 'SUCCESS';
          break;
        case 'set_invite_code':
        case 'set_forgot_code':
          if (p.code.length === 5) {
            endpoint = (function() {
              switch (act) {
                case 'set_invite_code':
                  return 'invite';
                default:
                  return 'forgot';
              }
            })();
            result = this.rest.doData("User_" + endpoint + "/" + (encodeURIComponent(p.code)), f, 'GET');
            if (result.invite || result.user) {
              this.invite_rec = (_ref = result.invite) != null ? _ref : result.user;
              this.invite_code = p.code;
              r.success = 'SUCCESS';
            }
          }
          if (!r.success) {
            i.add('INVALID_CODE', [p.code]);
            r.success = 'FAIL';
          }
          break;
        case 'pre_reg_confirm_code':
          if (p.code.length === 5) {
            result = this.rest.doData('PreReg/confirm', f, 'POST', {
              code: p.code
            });
            if (result.SUCCESS === true) {
              m.add('SUCCESS');
              r.success = 'SUCCESS';
            }
          }
          if (!r.success) {
            i.add('INVALID_CODE', [p.code]);
            r.success = 'FAIL';
          }
          break;
        case 'confirm_code':
          if (p.code.length === 5) {
            result = this.rest.doData("User_confirm/" + (encodeURIComponent(p.code)), f, 'POST');
            if (result.SUCCESS === true) {
              this.rest.login(result.user.email);
              m.add('SUCCESS');
              r.success = 'SUCCESS';
            }
          }
          if (!r.success) {
            i.add('INVALID_CODE', [p.code]);
            r.success = 'FAIL';
          }
          break;
        case 'populate_invite':
          this.xfer_details = $.extend({}, p);
          this.invite_display = {
            name: p.name,
            email: p.email
          };
          this.invalidateTables(['InviteDisplay']);
          r.success = 'SUCCESS';
          break;
        case 'invite':
        case 'invite_team':
        case 'invite_admin':
        case 'invite_admin_ltd':
          _ref1 = (function() {
            switch (act) {
              case 'invite_team':
                return ['teaminvite', 'UserInviteOther'];
              case 'invite_admin':
                return ['BROKEN', 'UserInviteAdam'];
              case 'invite_admin_ltd':
                return ['BROKEN', 'UserInviteAdamLtd'];
              default:
                return ['invite', 'UserInviteOther'];
            }
          })(), endpoint = _ref1[0], fist = _ref1[1];
          oF = this.Epic.getFistInstance(fist);
          i.call(oF.fieldLevelValidate(p, fist));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.post("User_" + endpoint, f, fv);
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
        case 'invite_team_project':
        case 'invite_admin_project':
          _ref2 = (function() {
            switch (act) {
              case 'invite_team_project':
                return ['invite', 'UserInviteProject'];
              case 'invite_admin_project':
                return ['BROKEN', 'UserInviteProjectAdam'];
            }
          })(), endpoint = _ref2[0], fist = _ref2[1];
          oF = this.Epic.getFistInstance(fist);
          i.call(oF.fieldLevelValidate(p, fist));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          fv.project_id = Number(p.project_id);
          result = this.rest.post("User_" + endpoint, f, fv);
          _log2(f, 'result', result);
          if (result.SUCCESS === true) {
            m.add('SENT', [fv.email]);
            oF.clearValues();
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'request_invite':
          oF = this.Epic.getFistInstance('RequestInvite');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.post('User_requestinvite', f, fv);
          _log2(f, 'result', result);
          if (result.SUCCESS === true) {
            m.add('SENT', [fv.email]);
            oF.clearValues();
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'resend_invite':
          result = this.rest.post("User/" + p.id + "/reinvite", f, {});
          _log2(f, 'result', result);
          if (result.SUCCESS === true) {
            m.add('RE_SENT');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'register':
          oF = this.Epic.getFistInstance('UserRegister');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          mExtern = this.Epic.getInstance('External');
          fv.terms_version = mExtern.version.terms_use;
          fv.privacy_version = mExtern.version.privacy;
          result = this.rest.doData("User_register", f, 'POST', fv);
          if (result.SUCCESS === true) {
            if (result.re_invite) {
              m.add('CONFIRM', [fv.email]);
              r.success = 'CONFIRM';
            } else {
              r.success = 'SUCCESS';
              this.rest.login(fv.email, fv.password);
            }
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'forgot_finish':
          oF = this.Epic.getFistInstance('UserForgotFinish');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.doData('User_forgotfinish', f, 'POST', fv);
          if (result.SUCCESS === true) {
            r.success = 'SUCCESS';
            this.rest.login(fv.email, fv.password);
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'save_profile':
        case 'save_profile_extended':
        case 'save_profile_expose':
          if (act !== 'save_profile_expose') {
            flist = act === 'save_profile' ? 'ProfileEdit' : 'ProfileExtended';
            oF = this.Epic.getFistInstance(flist);
            i.call(oF.fieldLevelValidate(p, flist));
            if (i.count() > 0) {
              r.success = 'FAIL';
              return [r, i, m];
            }
            fv = oF.getDbFieldValues();
          } else {
            fv = {};
            if ((_ref3 = p.onoffswitch) == null) {
              p.onoffswitch = {};
            }
            if ((_ref4 = p.onoffswitch_orig) == null) {
              p.onoffswitch_orig = {};
            }
            fv.contact_flag_on = (function() {
              var _results;
              _results = [];
              for (prid in p.onoffswitch) {
                if (!(prid in p.onoffswitch_orig)) {
                  _results.push(prid);
                }
              }
              return _results;
            })();
            fv.contact_flag_off = (function() {
              var _results;
              _results = [];
              for (prid in p.onoffswitch_orig) {
                if (!(prid in p.onoffswitch)) {
                  _results.push(prid);
                }
              }
              return _results;
            })();
          }
          _log2(f, 'fv', fv);
          result = this.rest.post('User/me/update', f, fv);
          if (result.SUCCESS === true) {
            if (result.email_sent === true) {
              m.add('SENT', [fv.email]);
            }
            delete this.c_myself;
            delete this.Table.Me;
            m.add('SUCCESS');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'save_password':
          oF = this.Epic.getFistInstance('ChangePass');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.post('User/me/updatepass', f, fv);
          if (result.SUCCESS === true) {
            oF.clearValues();
            m.add('SUCCESS');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'tab_home_clear':
        case 'tab_home_sign_in':
        case 'tab_home_request_invite':
          tab = act.slice('tab_home_'.length);
          if (this.tab_home !== tab) {
            this.tab_home = tab;
            this.invalidateTables(['Options']);
          }
          r.success = 'SUCCESS';
          break;
        default:
          return User.__super__.action.call(this, act, p);
      }
      return [r, i, m];
    };

    User.prototype.loadTable = function(tbl_nm) {
      var f, level_map, mbytes, me, now, rec, rest_results, result, results, row, _ref;
      f = "M:User::loadTable(" + tbl_nm + ")";
      switch (tbl_nm) {
        case 'Me':
          rec = this._getMyself();
          me = $.extend({
            expires_days: '',
            Stats: [],
            Plan: [],
            Payment: [],
            is_recommendation: '',
            recommended_price: '',
            has_spships: ''
          }, rec.users[0]);
          level_map = (_ref = this.rest.choices().users.level[me.level]) != null ? _ref : {
            type: 'none',
            perm: 0,
            nice: 'Pending'
          };
          me.can_add_projects = level_map.perm & this.rest.PERM_ADD_PROJECTS ? 'yes' : '';
          me.is_team_admin = level_map.token === 'team_admin' ? 'yes' : '';
          me.is_team_accountant = level_map.token === 'team_accountant' ? 'yes' : '';
          me.is_team_owner = level_map.type === 'parent' ? 'yes' : '';
          me.level_nice = level_map.nice;
          me.bytes_quota = (Number(me.mbytes_quota)) * 1024 * 1024;
          if (rec.is_recommendation === true) {
            me.is_recommendation = 'yes';
            me.recommended_price = rec.plan.estimated_price;
            now = new Date();
            me.expires_days = Math.round(((Date.parse(rec.payment.expires)) - now) / 86400000 + 1);
            if (me.expires_days < 0) {
              me.expires_days = 0;
            }
            me.Plan = [rec.plan];
            me.Stats = [rec.stats];
            me.has_spships = rec.stats.sponsorships;
          } else if ('payment' in rec) {
            me.Payment = [rec.payment];
            now = new Date();
            me.expires_days = Math.round(((Date.parse(rec.payment.expires)) - now) / 86400000 + 1);
            if (me.expires_days < 0) {
              me.expires_days = 0;
            }
          }
          this.Table[tbl_nm] = [me];
          break;
        case 'Options':
          row = {
            port: (window.EpicMvc.Extras.options.RestEndpoint.split(':'))[2]
          };
          row.tab_home_clear = this.tab_home === 'clear' ? 'yes' : '';
          row.tab_home_sign_in = this.tab_home === 'sign_in' ? 'yes' : '';
          row.tab_home_request_invite = this.tab_home === 'request_invite' ? 'yes' : '';
          this.Table[tbl_nm] = [row];
          break;
        case 'InviteDisplay':
          results = [this.invite_display];
          this.Table[tbl_nm] = results;
          break;
        case 'Invite':
          results = [
            {
              mailto: ''
            }
          ];
          this.Table[tbl_nm] = results;
          break;
        case 'LoginMsg':
          result = [];
          row = {};
          if (this.login_msg !== false) {
            rec = this._getMyself();
            $.extend(row, rec.stats);
            row.plan_price = rec.plan.base_price;
            row.plan_name = rec.plan.plan_name;
            now = new Date();
            row.expires_days = Math.round(((Date.parse(rec.payment.expires)) - now) / 86400000 + 1);
            if (row.expires_days < 0) {
              row.expires_days = 0;
            }
            row.is_expired = '';
            result.push(row);
          }
          this.Table[tbl_nm] = result;
          break;
        case 'DynaInfo':
          rest_results = this.rest.get('User/me/uploadedmbytes', f);
          mbytes = Number(rest_results.mbytes);
          results = [
            {
              mbytes_used: mbytes,
              bytes_used: mbytes * 1024 * 1024
            }
          ];
          this.Table[tbl_nm] = results;
          break;
        default:
          return User.__super__.loadTable.call(this, tbl_nm);
      }
    };

    User.prototype.fistLoadData = function(oFist) {
      var email, f, me, project, _ref;
      f = "M:User.fistLoadData(" + (oFist.getFistNm()) + ")";
      switch (oFist.getFistNm()) {
        case 'Login':
          return oFist.setFromDbValues({
            email: (_ref = window.EpicMvc.Extras.localCache.QuickGet('auth_user')) != null ? _ref : ''
          });
        case 'UserForgot':
          if (this.forgot_xfer_pswd) {
            oFist.setFromDbValues({
              email: this.forgot_xfer_pswd
            });
            return delete this.forgot_xfer_pswd;
          }
          break;
        case 'UserInviteOther':
        case 'UserInviteTeam':
        case 'UserInviteAdam':
        case 'UserInviteAdamLtd':
          me = this._getMyself().users[0];
          if (this.xfer_email !== false) {
            email = this.xfer_email;
            project = this.xfer_project;
            this.xfer_email = false;
            this.xfer_project = false;
          } else {
            email = '';
          }
          oFist.setFromDbValues({
            msg: "" + me.first_name + " " + me.last_name + " wants to invite you to join iProjectMobile.",
            email: email,
            project_id: project
          });
          oFist.setFromDbValues(this.xfer_details);
          return this.xfer_details = {};
        case 'UserInviteProject':
        case 'UserInviteProjectAdam':
          me = this._getMyself().users[0];
          if (this.xfer_email !== false) {
            email = this.xfer_email;
            project = this.xfer_project;
            this.xfer_email = false;
            this.xfer_project = false;
          } else {
            email = '';
          }
          oFist.setFromDbValues({
            email: email,
            project_id: project
          });
          oFist.setFromDbValues(this.xfer_details);
          return this.xfer_details = {};
        case 'ChangePass':
          return null;
        case 'UserRegister':
        case 'UserForgotFinish':
        case 'RequestInvite':
          if (this.invite_rec !== false) {
            return oFist.setFromDbValues(this.invite_rec);
          }
          break;
        case 'ProfileEdit':
        case 'ProfileExtended':
          return oFist.setFromDbValues(this._getMyself().users[0]);
        default:
          return User.__super__.fistLoadData.call(this, oFist);
      }
    };

    User.prototype.fistGetFieldChoices = function(oFist, field) {
      var choices, f, fdef, nm, o, options, rec, v, val, values, _ref;
      f = 'M:User.fistGetFieldChoices:' + oFist.getFistNm() + ':' + field;
      switch (field) {
        case 'State':
        case 'StateReq':
          options = [];
          values = [];
          fdef = oFist.getFieldAttributes(field);
          if ('choice' in fdef) {
            options.push(fdef.choice);
            values.push('');
          }
          _ref = window.state_codes;
          for (v in _ref) {
            o = _ref[v];
            options.push(o);
            values.push(v);
          }
          return {
            options: options,
            values: values
          };
        case 'LevelTeam':
          choices = (function() {
            var _ref1, _results;
            _ref1 = this.rest.choices().users.level;
            _results = [];
            for (nm in _ref1) {
              rec = _ref1[nm];
              if (rec.type === 'child') {
                _results.push([rec.sort, rec.nice, rec.token]);
              }
            }
            return _results;
          }).call(this);
          choices.sort(function(a, b) {
            return a[0] - b[0];
          });
          return {
            options: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = choices.length; _i < _len; _i++) {
                val = choices[_i];
                _results.push(val[1]);
              }
              return _results;
            })(),
            values: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = choices.length; _i < _len; _i++) {
                val = choices[_i];
                _results.push(val[2]);
              }
              return _results;
            })()
          };
        case 'Level':
          choices = (function() {
            var _ref1, _results;
            _ref1 = this.rest.choices().users.level;
            _results = [];
            for (nm in _ref1) {
              rec = _ref1[nm];
              if (rec.type !== 'child') {
                _results.push([rec.sort, rec.nice, rec.token]);
              }
            }
            return _results;
          }).call(this);
          choices.sort(function(a, b) {
            return a[0] - b[0];
          });
          return {
            options: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = choices.length; _i < _len; _i++) {
                val = choices[_i];
                _results.push(val[1]);
              }
              return _results;
            })(),
            values: (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = choices.length; _i < _len; _i++) {
                val = choices[_i];
                _results.push(val[2]);
              }
              return _results;
            })()
          };
        default:
          return User.__super__.fistGetFieldChoices.call(this, oFist, field);
      }
    };

    User.prototype._getMyself = function(force) {
      var f;
      f = 'M:User._getMyself';
      if (this.c_myself && force !== true) {
        return this.c_myself;
      }
      this.c_myself = this.rest.get('User/me', f);
      if (this.c_myself.is_recommendation !== true) {
        this.login_msg = false;
      }
      if ('plan' in this.c_myself) {
        $.extend(this.c_myself.plan, this.rest.choices().bt_plans.prefix[this.c_myself.plan.prefix]);
      }
      return this.c_myself;
    };

    User.prototype.UpdateUserAsync = function(cmd, rec) {
      var f;
      f = 'M:User.UpdateUserAsync:' + cmd;
      this._getMyself();
      _log2(f, 'c_myself/rec', this.c_myself, rec);
      $.extend(this.c_myself.users[0], rec);
      this.invalidateTables(['Me']);
    };

    return User;

  })(window.EpicMvc.ModelJS);

  window.EpicMvc.Model.User = User;

}).call(this);
