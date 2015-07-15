// Generated by CoffeeScript 1.4.0
(function() {
  var Rest;

  Rest = (function() {

    function Rest() {}

    Rest.localCache = function() {
      return window.EpicMvc.Extras.localCache;
    };

    Rest.rest_url = window.EpicMvc.Extras.options.RestEndpoint;

    Rest.rest_upload_url = window.EpicMvc.Extras.options.UploadEndpoint;

    Rest.statusCode = true;

    Rest.token = false;

    Rest.refresh_timer = false;

    Rest.auth_user = false;

    Rest.auth_web_client = 'web-client';

    Rest.counter = 0;

    Rest.choices_cache = false;

    Rest.PERM_ADD_PROJECTS = 1;

    Rest.choices = function() {
      var f;
      f = 'E:Rest.choices';
      if (this.choices_cache) {
        return this.choices_cache;
      }
      this.choices_cache = {
        global: {
          disposal: {
            0: {
              token: 'active',
              nice: 'Active'
            },
            1: {
              token: 'deleted',
              nice: 'Deleted'
            },
            2: {
              token: 'purge',
              nice: 'Purge'
            }
          }
        },
        members: {
          invited_as: {
            0: {
              token: 'member',
              nice: 'Member'
            },
            10: {
              token: 'manager',
              nice: 'Manager'
            },
            20: {
              token: 'owner',
              nice: 'Owner'
            },
            30: {
              token: 'watcher',
              nice: 'Watcher'
            },
            40: {
              token: 'admin',
              nice: 'Admin'
            }
          }
        },
        users: {
          level: {
            0: {
              sort: 0,
              type: 'free',
              token: 'free',
              nice: 'Restricted',
              perm: 0
            },
            4: {
              sort: 1,
              type: 'pay',
              token: 'starter',
              nice: 'Free',
              perm: 0
            },
            1: {
              sort: 2,
              type: 'pay',
              token: 'limited',
              nice: 'Starter',
              perm: 0
            },
            2: {
              sort: 3,
              type: 'pay',
              token: 'standard',
              nice: 'Standard',
              perm: this.PERM_ADD_PROJECTS
            },
            3: {
              sort: 4,
              type: 'pay',
              token: 'professional',
              nice: 'Professional',
              perm: this.PERM_ADD_PROJECTS
            },
            5: {
              sort: 5,
              type: 'adam',
              token: 'super',
              nice: 'Super User',
              perm: this.PERM_ADD_PROJECTS
            },
            6: {
              sort: 6,
              type: 'parent',
              token: 'team_owner',
              nice: 'Owner',
              perm: this.PERM_ADD_PROJECTS
            },
            7: {
              sort: 7,
              type: 'child',
              token: 'team_member',
              nice: 'Member',
              perm: 0
            },
            8: {
              sort: 8,
              type: 'child',
              token: 'team_manager',
              nice: 'Project Manager',
              perm: 0
            },
            9: {
              sort: 9,
              type: 'child',
              token: 'team_creator',
              nice: 'Project Creator',
              perm: this.PERM_ADD_PROJECTS
            },
            11: {
              sort: 10,
              type: 'child',
              token: 'team_accountant',
              nice: 'Account Manager',
              perm: this.PERM_ADD_PROJECTS
            },
            10: {
              sort: 11,
              type: 'child',
              token: 'team_admin',
              nice: 'Administrator',
              perm: this.PERM_ADD_PROJECTS
            }
          },
          status: {
            0: {
              token: 'pending',
              nice: 'Pending'
            },
            1: {
              token: 'valid',
              nice: 'Valid'
            }
          },
          bill_system: {
            0: {
              token: 'internal',
              nice: 'Internal'
            },
            1: {
              token: 'braintree',
              nice: 'Braintree'
            },
            2: {
              token: 'bank_check',
              nice: 'Bank Check'
            }
          }
        },
        invites: {
          status: {
            0: {
              token: 'new',
              nice: 'New'
            },
            1: {
              token: 'sent',
              nice: 'Sent'
            },
            2: {
              token: 'valid',
              nice: 'Valid'
            },
            3: {
              token: 'accepted',
              nice: 'Accepted'
            }
          }
        },
        bt_plans: {
          prefix: {
            FREE: {
              join: 3,
              create: 0,
              manage: 0
            },
            STR: {
              join: 'Unlimited',
              create: 0,
              manage: 0
            },
            STD: {
              join: 'Unlimited',
              create: 10,
              manage: 'Unlimited'
            },
            PRO: {
              join: 'Unlimited',
              create: 'Unlimited',
              manage: 'Unlimited'
            },
            TEAM: {
              join: 'Unlimited',
              create: 'Unlimited',
              manage: 'Unlimited'
            },
            TRIAL: {
              join: 'Unlimited',
              create: 'Unlimited',
              manage: 'Unlimited'
            }
          }
        },
        bt_invoice: {
          planId: {
            Team_Sandbox: {
              prefix: 'TEAM',
              nice: 'Team',
              desc: 'Team Account'
            },
            Professional_Sandbox: {
              prefix: 'PRO',
              nice: 'Professional',
              desc: 'Professional Account'
            },
            Standard_Sandbox: {
              prefix: 'STD',
              nice: 'Standard',
              desc: 'Standard Account'
            },
            Starter_Sandbox: {
              prefix: 'STR',
              nice: 'Starter',
              desc: 'Starter Account'
            },
            Team: {
              prefix: 'TEAM',
              nice: 'Team',
              desc: 'Team Account'
            },
            Professional: {
              prefix: 'PRO',
              nice: 'Professional',
              desc: 'Professional Account'
            },
            Standard: {
              prefix: 'STD',
              nice: 'Standard',
              desc: 'Standard Account'
            },
            Starter: {
              prefix: 'STR',
              nice: 'Starter',
              desc: 'Starter Account'
            }
          }
        }
      };
      return this.choices_cache;
    };

    Rest.makeIssue = function(issueObj, result, more_issue_params) {
      var f, i_params, i_token, param, parts, rMatch, rObj, _i, _len, _ref;
      f = 'E:Rest.makeIssue';
      i_token = 'UNRECOGNIZED';
      i_params = [];
      rObj = JSON.parse(result);
      _log(f, issueObj, result, rObj);
      if (rObj === false) {
        i_token = 'FALSE';
      } else if (typeof rObj === 'string') {
        if ((rMatch = rObj.match(/^Error: ([A-Za-z0-9_-]+)/))) {
          i_params.push(rObj);
          parts = rMatch[1].split('-');
          if (parts[1] === 'BTMSG') {
            i_token = parts[0] + '_' + parts[1];
            i_params.push((((rObj.split('-')).slice(2)).join('-')).replace(/\n/g, '<br>'));
          } else {
            i_token = rMatch[1].replace(/-/g, '_');
          }
        } else {
          i_token = 'REST_001_ERROR';
          i_params.push(rObj);
        }
      } else if ('code' in rObj && 'message' in rObj) {
        i_token = rObj.code;
        i_params.push(rObj.message);
      } else if ('error' in rObj) {
        i_token = rObj.error;
      } else {
        i_params.push(JSON.stringify(rObj));
      }
      _ref = more_issue_params || [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        param = _ref[_i];
        i_params.push(param);
      }
      return issueObj.add(i_token, i_params);
    };

    Rest.get = function(resource, caller_info, data) {
      return this.rest(resource, caller_info, 'GET', data);
    };

    Rest.post = function(resource, caller_info, data) {
      return this.rest(resource, caller_info, 'POST', data);
    };

    Rest.download_file = function(url, cb) {
      var f, xhr;
      f = 'E:Rest.download_file';
      xhr = new XMLHttpRequest();
      xhr.onloadend = function(e) {
        if (this.status === 200) {
          return cb('success', this.response);
        } else {
          _log(f, 'fail', xhr);
          return cb('fail', this.response);
        }
      };
      xhr.onprogress = function(e) {
        return cb('progress', e.loaded, e.total);
      };
      xhr.open('GET', url, true);
      xhr.responseType = 'blob';
      cb('start');
      xhr.send();
      return xhr;
    };

    Rest.upload_file = function(prid, foid, file, action, cb) {
      var formData, options, resource, rest_url, xhr,
        _this = this;
      formData = new FormData();
      formData.append('file', file);
      resource = "" + prid + "/" + foid;
      if (action) {
        resource += "/" + action.parent_id + "/" + action.type;
      }
      rest_url = this.rest_upload_url;
      options = {
        url: this.rest_upload_url + resource,
        async: true,
        dataType: 'json',
        processData: false,
        contentType: false,
        type: 'POST',
        data: formData,
        progress: function(e) {
          return cb('progress', e.loaded, e.total);
        },
        beforeSend: function() {
          return cb('start');
        }
      };
      options.headers = {
        Authorization: "" + this.token.token_type + " " + this.token.access_token
      };
      xhr = ($.ajax(options)).always(function(data, textStatus, errorThrown) {
        if (textStatus === 'success') {
          return cb('success', data);
        } else {
          return cb('fail', data);
        }
      });
      return xhr;
    };

    Rest.rest = function(resource, caller_info, method, data_obj, special) {
      var f, reloading, results;
      f = "E:Rest.rest(" + caller_info + ")[" + resource + "]";
      results = this.doData(resource, caller_info, method, data_obj, special);
      if (results === false && this.statusCode === 'Unauthorized') {
        reloading = this.token === false ? 'rest1' : 'rest2';
        this.doToken();
        if (this.token === false) {

        } else {
          results = this.doData(resource, caller_info, method, data_obj, special);
        }
      }
      return results;
    };

    Rest.doToken = function(pass) {
      var f, rtoken,
        _this = this;
      f = 'E:Rest:@doToken';
      if (pass) {
        this.token = this.doData('Auth', '@doToken-user/pass', 'POST', {
          username: this.auth_user,
          password: pass,
          grant_type: 'password',
          client_id: this.auth_web_client
        });
      } else {
        if (this.token === false) {
          this.localCache().Restore();
          rtoken = this.localCache().Get('auth_rtoken');
          if (rtoken != null ? rtoken.length : void 0) {
            this.token = {
              refresh_token: rtoken
            };
          }
        }
        if (this.token) {
          this.token = this.doData('Auth', '@doToken-refresh', 'POST', {
            refresh_token: this.token.refresh_token,
            grant_type: 'refresh_token',
            client_id: this.auth_web_client
          });
        }
      }
      if (this.token) {
        if (pass) {
          this.localCache().Login({
            auth_rtoken: this.token.refresh_token
          });
        } else {
          this.localCache().Put('auth_rtoken', this.token.refresh_token);
        }
        if (this.refresh_timer === false) {
          this.refresh_timer = setTimeout((function() {
            _this.refresh_timer = false;
            return _this.doToken();
          }), (this.token.expires_in - 10) * 1000);
        }
      } else if (this.statusCode === 'Unauthorized' && !pass) {
        this.localCache().Logout();
        if (this.refresh_timer !== false) {
          clearTimeout(this.refresh_timer);
          this.refresh_timer = false;
        }
        window.EpicMvc.Epic.logout('Security.rest1', {});
      }
      return this.token;
    };

    Rest.login = function(auth_user, pass) {
      this.logout();
      this.auth_user = auth_user;
      this.localCache().QuickPut('auth_user', this.auth_user);
      if (pass) {
        return this.doToken(pass);
      }
    };

    Rest.logout = function() {
      this.auth_user = this.token = false;
      this.localCache().Logout();
      if (this.refresh_timer !== false) {
        clearTimeout(this.refresh_timer);
        this.refresh_timer = false;
      }
    };

    Rest.doData = function(resource, caller_info, method, data_obj, special) {
      var f, options, rest_url, results,
        _this = this;
      f = "E:Rest.doData(" + caller_info + ")[" + resource + "]";
      if (data_obj == null) {
        data_obj = {};
      }
      results = [];
      rest_url = this.rest_url;
      if (special) {
        rest_url = this.rest_upload_url;
      }
      options = {
        cache: false,
        url: rest_url + resource,
        async: false,
        dataType: 'json'
      };
      if (special) {
        options.processData = false;
        options.contentType = false;
      }
      if (typeof method === 'string') {
        $.extend(options, {
          type: method,
          data: data_obj
        });
      }
      if (this.token !== false) {
        options.url += '?auth_token=' + encodeURIComponent("" + this.token.access_token);
      }
      ($.ajax(options)).always(function(data, textStatus, errorThrown) {
        var statusCode, xhr;
        if (textStatus === 'success') {
          _this.statusCode = true;
          if ('result' in data) {
            if ('SUCCESS' in data.result) {
              results = data.result;
              return;
            }
          } else if ('JSON' in data) {
            results = data.JSON;
          } else {
            results = data;
          }
        } else {
          xhr = data;
          _log(f, {
            statusCode: _this.statusCode,
            errorThrown: errorThrown,
            xhr: xhr
          });
          statusCode = typeof errorThrown === 'string' ? errorThrown : errorThrown.name;
          _log2(f, statusCode, xhr.responseText);
          switch (statusCode) {
            case 'Unauthorized':
              results = false;
              break;
            case 'Forbidden':
            case 'Not Found':
            case 'Bad Request':
            case 'Internal Server Error':
              results = xhr.responseText;
              _this.statusCode = true;
              break;
            case 'NS_ERROR_FAILURE':
            case 'Failure':
            case 'NETWORK_ERR':
              if (_this.statusCode !== 'Failure') {
                alert('Remote server is unavailable.');
              }
              results = false;
              break;
            default:
              alert('Session timed out.  Click to resume.');
              results = false;
          }
          return _this.statusCode = statusCode;
        }
      });
      return results;
    };

    return Rest;

  })();

  window.EpicMvc.Extras.Rest = Rest;

}).call(this);