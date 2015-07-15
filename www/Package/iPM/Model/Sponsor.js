// Generated by CoffeeScript 1.4.0
(function() {
  var Sponsor,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Sponsor = (function(_super) {

    __extends(Sponsor, _super);

    function Sponsor(Epic, view_nm) {
      var ss;
      ss = Sponsor.__super__.constructor.call(this, Epic, view_nm, ss);
      this.rest = window.EpicMvc.Extras.Rest;
      this.sponsor_add_issue = false;
      this.sponsor_add_open = false;
      this.sponsor_add_rows = [];
      this.c_sponsor_data = false;
    }

    Sponsor.prototype.eventLogout = function() {
      return true;
    };

    Sponsor.prototype.eventNewRequest = function() {
      delete this.Table.Sponsor;
      delete this.Table.Owner;
      delete this.c_projects;
      return this.c_sponsor_data = false;
    };

    Sponsor.prototype.action = function(act, p) {
      var bad_rows, count, f, form_issues, fv, h_map, i, i_map, i_row, id, ix, key, line, m, map, me, member, oF, oFist, project, r, result, row, save, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref2;
      f = "M:Sponsor::action(" + act + ")";
      _log(f, p);
      r = {};
      i = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      m = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      switch (act) {
        case 'clear_new_sponsor_rows':
          oF = this.Epic.getFistInstance('AddNewTeamUser');
          oF.clearValues();
          this.sponsor_add_rows = [];
          this.invalidateTables(['SponsorAddRows']);
          break;
        case 'invite_new_sponsor_row':
          map = window.EpicMvc['issues$' + this.Epic.appConf().getGroupNm()];
          oF = this.Epic.getFistInstance('AddNewTeamUser');
          row = this.sponsor_add_rows[p.id];
          delete row.error;
          i_row = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
          oF.clearValues();
          i_row.call(oF.fieldLevelValidate(row));
          save = {
            issues: oF.fb_issues,
            html: oF.fb_HTML
          };
          if (i_row.count() > 0) {
            r.success = 'FAIL';
          } else {
            fv = oF.getDbFieldValues();
            result = this.rest.post("Sponsor/email/add", f, fv);
            if (result.SUCCESS === true) {
              row.success = true;
            } else {
              this.rest.makeIssue(i_row, result);
              row.error = i_row.asTable(map)[0].issue;
            }
          }
          oF.clearValues();
          if (row.success) {
            this.sponsor_add_rows.splice(Number(p.id), 1);
            m.add('INVITE_SPONSOR_ROW_SUCCESS', [row.TeamEmail]);
          } else {
            for (key in save.issues) {
              oF.fb_issues[key + '__' + p.id] = save.issues[key];
            }
            for (key in save.html) {
              row[key] = save.html[key];
            }
          }
          this.invalidateTables(['SponsorAddRows']);
          break;
        case 'update_new_sponsor_field':
          this.sponsor_add_rows[p.id][p.name] = $(p.input_obj).val();
          oFist = this.Epic.getFistInstance('AddNewTeamUser');
          oFist.fb_HTML[p.name + '__' + p.id] = $(p.input_obj).val();
          break;
        case 'send_new_sponsor_rows':
          form_issues = [];
          bad_rows = [];
          map = window.EpicMvc['issues$' + this.Epic.appConf().getGroupNm()];
          oF = this.Epic.getFistInstance('AddNewTeamUser');
          _ref = this.sponsor_add_rows;
          for (ix = _i = 0, _len = _ref.length; _i < _len; ix = ++_i) {
            row = _ref[ix];
            i_row = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
            row.error = '';
            row.error_token = '';
            row.is_invitable = false;
            oF.clearValues();
            i_row.call(oF.fieldLevelValidate(row));
            if (i_row.count() > 0) {
              r.success = 'FAIL';
            } else {
              fv = oF.getDbFieldValues();
              result = this.rest.post("User_teaminvite", f, fv);
              if (result.SUCCESS === true) {
                row.success = true;
              } else {
                me = (this.Epic.getInstance('User'))._getMyself();
                this.rest.makeIssue(i_row, result, [me.users[0].sponsorships]);
                row.error_token = i_row.asTable(map)[0].token;
                row.error = i_row.asTable(map)[0].issue;
                if (result === '"Error: REST_403_USER_EMAIL_EXISTS"') {
                  row.is_invitable = true;
                }
              }
            }
            if (!row.success) {
              form_issues.push([bad_rows.length, oF.fb_issues, oF.fb_HTML]);
              bad_rows.push(row);
            }
          }
          count = this.sponsor_add_rows.length - bad_rows.length;
          oF.clearValues();
          if (bad_rows.length) {
            if (form_issues.length) {
              i.add('FORM_ERRORS');
              for (_j = 0, _len1 = form_issues.length; _j < _len1; _j++) {
                line = form_issues[_j];
                row = line[0], i_map = line[1], h_map = line[2];
                for (key in i_map) {
                  oF.fb_issues[key + '__' + row] = i_map[key];
                }
                for (key in h_map) {
                  bad_rows[row][key] = h_map[key];
                }
              }
            }
          } else {
            r.success = 'SUCCESS';
          }
          if (count > 0) {
            m.add('ADD_SPONSOR_ROW_SUCCESS', [count]);
          }
          this.sponsor_add_rows = bad_rows;
          this.invalidateTables(['SponsorAddRows']);
          break;
        case 'sponsor_del':
          id = Number(p.id);
          result = this.rest.post('Sponsor/' + id + '/remove', f);
          if (result.SUCCESS === true) {
            if (result.projects_without_owners.length) {
              m.add('OWNERS_REMOVED');
              _ref1 = result.projects_without_owners;
              for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
                project = _ref1[_k];
                m.add('NO_OWNER_FOR_PROJECT', [project.name]);
              }
            }
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
        case 'add_new_sponsor_row':
          this.sponsor_add_rows.push({});
          this.invalidateTables(['SponsorAddRows']);
          break;
        case 'remove_team_user_row':
          this.sponsor_add_rows.splice(Number(p.id), 1);
          oFist = this.Epic.getFistInstance('AddNewTeamUser');
          oFist.clearValues();
          this.invalidateTables(['SponsorAddRows']);
          break;
        case 'sponsor_level':
          result = this.rest.post("Sponsor/" + p.id + "/updatelevel", f, {
            level: p.as
          });
          if (result.SUCCESS === true) {
            if (result.projects_without_owners.length) {
              m.add('OWNERS_REMOVED');
              _ref2 = result.projects_without_owners;
              for (_l = 0, _len3 = _ref2.length; _l < _len3; _l++) {
                project = _ref2[_l];
                m.add('NO_OWNER_FOR_PROJECT', [project.name]);
              }
            }
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
        case 'choose_team_user':
          member = p.id ? Number(p.id) : false;
          if (this.member_edit !== member) {
            this.member_edit = member;
            this.invalidateTables(['Sponsor']);
          }
          r.success = 'SUCCESS';
          break;
        case 'save_team_user':
          oF = this.Epic.getFistInstance('ModifyTeamUser');
          i.call(oF.fieldLevelValidate(p));
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = oF.getDbFieldValues();
          result = this.rest.post("User/" + this.member_edit + "/reinvite", f, fv);
          if (result.SUCCESS === true) {
            this.invalidateTables(['Sponsor']);
            m.add('RE_SENT');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        default:
          return Sponsor.__super__.action.call(this, act, p);
      }
      return [r, i, m];
    };

    Sponsor.prototype.loadTable = function(tbl_nm) {
      var data, f, id, member, members, new_row, owner, owners, rec, rest_results, results, row, table, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      f = "M:Sponsor::loadTable(" + tbl_nm + ")";
      switch (tbl_nm) {
        case 'Sponsor':
          rest_results = this._getSponsorData();
          results = [];
          _ref1 = (_ref = rest_results.sponsors) != null ? _ref : [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            row = _ref1[_i];
            new_row = $.extend({}, row, {
              is_edit: ''
            });
            new_row.level_nice = (_ref2 = (_ref3 = this.rest.choices().users.level[row.level]) != null ? _ref3.nice : void 0) != null ? _ref2 : '?';
            new_row.level_token = (_ref4 = (_ref5 = this.rest.choices().users.level[row.level]) != null ? _ref5.token : void 0) != null ? _ref4 : '?';
            if (new_row.id === this.member_edit) {
              new_row.is_edit = 'yes';
            }
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
        case 'SponsorAddRows':
          table = [];
          id = 0;
          _ref6 = this.sponsor_add_rows;
          for (_j = 0, _len1 = _ref6.length; _j < _len1; _j++) {
            row = _ref6[_j];
            new_row = $.extend({
              error: '',
              is_invitable: ''
            }, row, {
              id: id++
            });
            new_row.level_nice = (_ref7 = (_ref8 = this.rest.choices().users.level[row.level]) != null ? _ref8.nice : void 0) != null ? _ref7 : '?';
            new_row.level_token = (_ref9 = (_ref10 = this.rest.choices().users.level[row.level]) != null ? _ref10.token : void 0) != null ? _ref9 : '?';
            table.push(new_row);
          }
          this.Table[tbl_nm] = table;
          break;
        case 'Owner':
          data = this.rest.get('Project_team', f);
          owners = {};
          members = {};
          _ref12 = (_ref11 = data.owners) != null ? _ref11 : [];
          for (_k = 0, _len2 = _ref12.length; _k < _len2; _k++) {
            rec = _ref12[_k];
            owners[rec.project_id] = rec;
          }
          _ref14 = (_ref13 = data.memberships) != null ? _ref13 : [];
          for (_l = 0, _len3 = _ref14.length; _l < _len3; _l++) {
            rec = _ref14[_l];
            members[rec.project_id] = rec;
          }
          results = [];
          _ref15 = data.projects;
          for (_m = 0, _len4 = _ref15.length; _m < _len4; _m++) {
            row = _ref15[_m];
            if (!(row.type === 1)) {
              continue;
            }
            owner = (_ref16 = owners[row.id]) != null ? _ref16 : {
              first_name: '',
              last_name: '',
              email: 'NONE'
            };
            member = (_ref17 = members[row.id]) != null ? _ref17 : {
              invited_as: 'NONE'
            };
            new_row = $.extend({}, row, owner, member);
            new_row.invited_as_nice = (_ref18 = (_ref19 = this.rest.choices().members.invited_as[new_row.invited_as]) != null ? _ref19.nice : void 0) != null ? _ref18 : '';
            new_row.invited_as_token = (_ref20 = (_ref21 = this.rest.choices().members.invited_as[new_row.invited_as]) != null ? _ref21.token : void 0) != null ? _ref20 : '';
            new_row.is_watching = ((_ref22 = this.rest.choices().members.invited_as[new_row.invited_as]) != null ? _ref22.token : void 0) === 'watcher' ? 'yes' : '';
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
        default:
          Sponsor.__super__.loadTable.call(this, tbl_nm);
      }
    };

    Sponsor.prototype.fistLoadData = function(oFist) {
      var f, ix, rest_results, row, _i, _j, _len, _len1, _ref, _ref1, _ref2, _results, _results1;
      f = "M:Sponsor.fistLoadData(" + (oFist.getFistNm()) + ")";
      switch (oFist.getFistNm()) {
        case 'SponsorAddEmail':
          return null;
        case 'AddNewTeamUser':
          _ref = this.sponsor_add_rows;
          _results = [];
          for (ix = _i = 0, _len = _ref.length; _i < _len; ix = ++_i) {
            row = _ref[ix];
            oFist.fb_HTML['FirstName__' + ix] = row.FirstName;
            oFist.fb_HTML['LastName__' + ix] = row.LastName;
            oFist.fb_HTML['TeamEmail__' + ix] = row.TeamEmail;
            _results.push(oFist.fb_HTML['LevelTeam__' + ix] = row.LevelTeam);
          }
          return _results;
          break;
        case 'ModifyTeamUser':
          rest_results = this._getSponsorData();
          _ref2 = (_ref1 = rest_results.sponsors) != null ? _ref1 : [];
          _results1 = [];
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            row = _ref2[_j];
            if (row.id === this.member_edit) {
              oFist.setFromDbValues(row);
              break;
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
          break;
        default:
          return Sponsor.__super__.fistLoadData.call(this, oFist);
      }
    };

    Sponsor.prototype.fistGetFieldChoices = function(oFist, field) {
      var f, nm, rec, results, val;
      f = 'M:Sponsor.fistGetFieldChoices:' + oFist.getFistNm() + ':' + field;
      _log2(f, oFist);
      switch (field) {
        case 'LevelTeam':
          results = (function() {
            var _ref, _results;
            _ref = this.rest.choices().users.level;
            _results = [];
            for (nm in _ref) {
              val = _ref[nm];
              if (val.type === 'child') {
                _results.push([val.sort, val.nice, val.token]);
              }
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
        default:
          return Sponsor.__super__.fistGetFieldChoices.call(this, oFist, field);
      }
    };

    Sponsor.prototype._getSponsorData = function() {
      var f;
      f = "M:Sponsor._getSponsorData";
      if (this.c_sponsor_data) {
        return this.c_sponsor_data;
      }
      return this.c_sponsor_data = this.rest.get('Sponsor', f);
    };

    return Sponsor;

  })(window.EpicMvc.ModelJS);

  window.EpicMvc.Model.Sponsor = Sponsor;

}).call(this);
