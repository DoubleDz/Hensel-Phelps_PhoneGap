// Generated by CoffeeScript 1.4.0
(function() {
  var Billing,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Billing = (function(_super) {

    __extends(Billing, _super);

    function Billing(Epic, view_nm) {
      var ss;
      ss = {
        new_plan_id: false
      };
      Billing.__super__.constructor.call(this, Epic, view_nm, ss);
      this.rest = window.EpicMvc.Extras.Rest;
      this._reset();
    }

    Billing.prototype.eventLogout = function() {
      return true;
    };

    Billing.prototype.eventNewRequest = function(change) {
      if (this.c_billing === false) {
        return;
      }
      if (change.track !== true) {
        return;
      }
      if ((this.Epic.getViewTable('Pageflow/V'))[0].billing_track === true) {
        return;
      }
      this._reset();
      return (this.Epic.getFistInstance('CardInfo')).clearValues();
    };

    Billing.prototype._reset = function(force) {
      var me, plan_prefix, _ref;
      this.c_billing = false;
      me = (this.Epic.getInstance('User'))._getMyself(force);
      if (me.users[0].bill_system === 1) {
        plan_prefix = ((_ref = me.users[0].bill_state) != null ? _ref.split('-') : void 0)[1];
        this.c_selected_plan = {
          extra_gblocks: me.payment.gblock_qty,
          extra_users: me.payment.spship_qty,
          prefix: plan_prefix
        };
        this.c_current_plan = $.extend({}, this.c_selected_plan);
        delete this.c_card_info;
        delete this.c_history;
        delete this.c_recommend;
      }
      this.c_invoice_detail = false;
      return this.invalidateTables(true);
    };

    Billing.prototype.action = function(act, p) {
      var f, fv, gblocks_ok, good, i, m, oF, plan, plan_ok, r, result, users_ok, val, what, who, _ref, _ref1;
      f = "M:Billing::action(" + act + ")";
      _log(f, p);
      r = {};
      i = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      m = new window.EpicMvc.Issue(this.Epic, this.view_nm, act);
      this._getBilling();
      switch (act) {
        case 'check_for_card':
          r.card = 'last4' in this._getCardInfo() ? 'YES' : 'NO';
          break;
        case 'select_invoice':
          result = this.rest.get('User/me/History/' + p.id, f);
          if ('history' in result) {
            this.c_invoice_detail = result.history;
            this.invalidateTables(['SelectedInvoice']);
            r.success = 'SUCCESS';
          } else {
            m.add('NO_HISTORY_ID', p.id);
          }
          break;
        case 'select_plan_default':
          if ((_ref = this.c_selected_plan.prefix) === 'TRIAL' || _ref === 'FREE') {
            if (this.c_recommend.plan) {
              this.c_selected_plan.prefix = this.c_recommend.plan.prefix;
              this.c_selected_plan.extra_users = this.c_recommend.plan.min_extra_users;
              this.c_selected_plan.extra_gblocks = this.c_recommend.plan.min_extra_gblocks;
            }
            this.invalidateTables(['SelectedPlan']);
          }
          break;
        case 'select_plan':
          if (p.prefix !== this.c_selected_plan.prefix) {
            plan_ok = !(this.c_recommend != null) || (this.c_recommend.ordered_levels.indexOf(this.c_recommend.min_req_level)) <= this.c_recommend.ordered_levels.indexOf(this.c_braintree[p.prefix].level);
            if (plan_ok) {
              this.c_selected_plan.prefix = p.prefix;
              this.invalidateTables(['SelectedPlan']);
              r.success = 'SUCCESS';
            } else {
              i.add('PLAN_TOO_LOW', [this.c_recommend.plan.plan_name]);
              r.success = 'FAIL';
            }
          }
          break;
        case 'capacity_plus':
        case 'capacity_minus':
        case 'user_plus':
        case 'user_minus':
          m = {
            capacity: 'extra_gblocks',
            user: 'extra_users',
            plus: 1,
            minus: -1
          };
          f = {
            capacity: 'ExtraGBlocks',
            user: 'ExtraUsers'
          };
          _ref1 = act.split('_'), who = _ref1[0], what = _ref1[1];
          val = this.c_selected_plan[m[who]];
          val += m[what];
          if (val < 0) {
            val = 0;
          }
          if (this.c_selected_plan[m[who]] !== val) {
            this.c_selected_plan[m[who]] = val;
            oF = this.Epic.getFistInstance('ProfileAddon');
            oF.fb_HTML[f[who]] = val;
            this.invalidateTables(['SelectedPlan']);
          }
          break;
        case 'onchange_ProfileAddon':
          m = {
            ExtraGBlocks: 'extra_gblocks',
            ExtraUsers: 'extra_users'
          };
          val = Number(p.value);
          if (isNaN(val)) {
            val = 0;
          }
          oF = this.Epic.getFistInstance('ProfileAddon');
          oF.fb_HTML[p.field] = p.value;
          if (this.c_selected_plan[m[p.field]] !== val) {
            this.c_selected_plan[m[p.field]] = val;
            this.invalidateTables(['SelectedPlan']);
          }
          r.success = 'SUCCESS';
          break;
        case 'validate_plan_update':
          plan = this.c_braintree[this.c_selected_plan.prefix];
          plan_ok = (this.c_recommend.ordered_levels.indexOf(this.c_recommend.min_req_level)) <= this.c_recommend.ordered_levels.indexOf(plan.level);
          gblocks_ok = this.c_selected_plan.extra_gblocks >= this.c_recommend.plans[plan.level].min_extra_gblocks;
          users_ok = this.c_selected_plan.extra_users >= this.c_recommend.plans[plan.level].min_extra_users;
          if (!plan_ok) {
            i.add('PLAN_TOO_LOW', [this.c_recommend.plan.plan_name]);
            r.success = 'FAIL';
            return [r, i, m];
          } else if (!gblocks_ok || !users_ok) {
            if (!gblocks_ok) {
              i.add('GBLOCKS_TOO_LOW', [this.c_recommend.plans[plan.level].min_extra_gblocks]);
            }
            if (!users_ok) {
              i.add('USERS_TOO_LOW', [this.c_recommend.plans[plan.level].min_extra_users]);
            }
            r.success = 'FAIL';
            return [r, i, m];
          }
          good = false;
          if (this.c_selected_plan.prefix !== this.c_current_plan.prefix) {
            good = true;
          }
          if (this.c_braintree[this.c_selected_plan.prefix].gblock_price) {
            if (this.c_selected_plan.extra_gblocks !== this.c_current_plan.extra_gblocks) {
              good = true;
            }
          }
          if (this.c_braintree[this.c_selected_plan.prefix].spship_price) {
            if (this.c_selected_plan.extra_users !== this.c_current_plan.extra_users) {
              good = true;
            }
          }
          if (good) {
            r.success = 'SUCCESS';
          } else {
            i.add('NO_PLAN_CHANGE');
            r.success = 'FAIL';
          }
          break;
        case 'purchase':
          fv = $.extend({}, this.c_selected_plan);
          plan = this.c_braintree[this.c_selected_plan.prefix];
          fv.plan_id = plan.id;
          if (plan.gblock_price === 0) {
            fv.extra_gblocks = 0;
          }
          if (plan.spship_price === 0) {
            fv.extra_users = 0;
          }
          result = this.rest.post('User/me/purchase', f, fv);
          if (result.SUCCESS === true) {
            this._reset(true);
            (this.Epic.getInstance('User')).UpdateUserAsync('merge', result.updated_user);
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'update_card':
          oF = this.Epic.getFistInstance('CardInfo');
          i.call(oF.fieldLevelValidate(p));
          this._checkCcExp(i, oF);
          if (i.count() > 0) {
            r.success = 'FAIL';
            return [r, i, m];
          }
          fv = this._encryptFields(oF.getDbFieldValues());
          result = this.rest.post("User/me/account", f, fv);
          if (result.SUCCESS === true) {
            this.c_card_info = result.card;
            if (result.retry_sub === true) {
              if (result.retry_result === true) {
                m.add('RETRY_SUB_SUCCESS');
              } else {
                i.add('RETRY_SUB_FAIL');
              }
            }
            oF.clearValues();
            this.invalidateTables(['MyCard']);
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'cancel_plan':
          result = this.rest.post('User/me/cancelplan', f, fv);
          if (result.SUCCESS === true) {
            (this.Epic.getInstance('User')).UpdateUserAsync('merge', result.updated_user);
            this.invalidateTables(['MyCard']);
            m.add('PLAN_CANCEL');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'uncancel_plan':
          result = this.rest.post('User/me/uncancelplan', f, fv);
          if (result.SUCCESS === true) {
            (this.Epic.getInstance('User')).UpdateUserAsync('merge', result.updated_user);
            this.invalidateTables(['MyCard']);
            m.add('PLAN_UNCANCEL');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        case 'remove_card':
          result = this.rest.post('User/me/removeaccount', f, fv);
          if (result.SUCCESS === true) {
            this.invalidateTables(['MyCard']);
            m.add('CARD_REMOVED');
            r.success = 'SUCCESS';
          } else {
            this.rest.makeIssue(i, result);
            r.success = 'FAIL';
          }
          break;
        default:
          return Billing.__super__.action.call(this, act, p);
      }
      return [r, i, m];
    };

    Billing.prototype.loadTable = function(tbl_nm) {
      var addon_map, card_info, dt, f, gblocks, group_nm, key, me, myPlanState, myself, new_row, nm, o_list, r, rec, row, table, total, users, _i, _len, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
      f = "M:Billing::loadTable(" + tbl_nm + ")";
      this._getBilling();
      switch (tbl_nm) {
        case 'Bankcheck':
          table = [];
          _ref = this.c_bank_check;
          for (nm in _ref) {
            row = _ref[nm];
            new_row = $.extend({}, row);
            table.push(new_row);
          }
          this.Table[tbl_nm] = table;
          break;
        case 'Plan':
          myPlanState = (_ref1 = (this.Epic.getViewTable('User/Me'))[0].bill_state) != null ? _ref1.split('-') : void 0;
          if (!myPlanState) {
            this.Table[tbl_nm] = [];
            return;
          }
          table = [];
          _ref2 = this.c_braintree;
          for (key in _ref2) {
            row = _ref2[key];
            if (!(key !== 'TRIAL' && key !== 'FREE')) {
              continue;
            }
            new_row = $.extend({}, row, {
              is_current: ''
            });
            new_row.join = this.rest.choices().bt_plans.prefix[row.prefix].join;
            new_row.create = this.rest.choices().bt_plans.prefix[row.prefix].create;
            new_row.manage = this.rest.choices().bt_plans.prefix[row.prefix].manage;
            new_row.is_join_unlimited = new_row.join === 999999 ? 'yes' : '';
            new_row.is_create_unlimited = new_row.create === 999999 ? 'yes' : '';
            if (row.token === myPlanState[1]) {
              new_row.is_current = 'yes';
            }
            new_row.users = 1 + row.base_spships;
            table.push(new_row);
          }
          table.sort(function(a, b) {
            return a.base_price - b.base_price;
          });
          this.Table[tbl_nm] = table;
          break;
        case 'Overview':
          myself = (this.Epic.getInstance('User'))._getMyself();
          me = myself.users[0];
          if (me.bill_system === 0) {
            this.Table[tbl_nm] = [
              {
                plan_name: 'Admin'
              }
            ];
            return;
          }
          myPlanState = me.bill_state.split('-');
          if (me.bill_system === 2) {
            row = $.extend({}, this.c_bank_check_prefixed[myPlanState[1]], myself.payment, myself.stats);
          } else {
            row = $.extend({
              Recommend: []
            }, this.c_braintree[myPlanState[1]], myself.payment, myself.stats);
            if (myself.is_recommendation) {
              row.Recommend = [$.extend({}, myself.plan)];
            }
          }
          row.allowed_gigs = (row.mbytes_quota + me.extra_quota) / 1024;
          row.allowed_users = (Number(row.sponsorships)) + (Number(me.extra_sponsorships)) + 1;
          row.total = row.base_price + row.spship_qty * row.spship_price + row.gblock_qty * row.gblock_price;
          _log2(f, row.prefix, this.rest.choices().bt_plans.prefix[row.prefix]);
          $.extend(row, this.rest.choices().bt_plans.prefix[row.prefix]);
          this.Table[tbl_nm] = [row];
          break;
        case 'MyCard':
          myself = (this.Epic.getInstance('User'))._getMyself();
          me = myself.users[0];
          if (me.bill_system === 0) {
            this.Table[tbl_nm] = [
              {
                is_card: ''
              }
            ];
            return;
          }
          myPlanState = me.bill_state.split('-');
          card_info = this._getCardInfo();
          row = $.extend({
            is_card: '',
            can_cancel: '',
            is_canceled: '',
            nextBillDate: '',
            billingPeriodStartDate: '',
            billingPeriodEndDate: ''
          }, card_info);
          if ('last4' in row) {
            if ('last4' in row) {
              row.is_card = true;
            }
            dt = new Date((Date.parse(row.billingPeriodEndDate + 'T00:00:00Z')) + 24 * 60 * 60 * 1000);
            row.nextBillDate = "" + (dt.getUTCFullYear()) + "-" + (dt.getUTCMonth() + 1) + "-" + (dt.getUTCDate());
            _log2(f, me.bill_system, myPlanState);
            if (myPlanState[2] === 'CANCELED') {
              row.is_canceled = 'yes';
            }
            if (me.bill_system === 1 && myPlanState[2] !== 'CANCELED' && ((_ref3 = myPlanState[1]) !== 'TRIAL' && _ref3 !== 'FREE')) {
              row.can_cancel = 'yes';
            }
          }
          this.Table[tbl_nm] = [row];
          break;
        case 'SelectedInvoice':
          row = $.extend({
            has_moreSpace: '',
            has_moreUsers: '',
            is_prorated: ''
          }, this.c_invoice_detail, this.rest.choices().bt_invoice.planId[this.c_invoice_detail.planId]);
          total = 0;
          addon_map = {
            Storage_Space_50: 'moreSpace',
            User_Add_On: 'moreUsers'
          };
          o_list = {
            creditCard: row.creditCard,
            subscription: row.subscription,
            plan: this.c_braintree[row.prefix]
          };
          _ref4 = row.addOns;
          for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
            rec = _ref4[_i];
            o_list[addon_map[rec.id]] = rec;
            row['has_' + addon_map[rec.id]] = 'yes';
            total += (row.moreSpace_extendedAmount = rec.amount * rec.quantity);
          }
          for (group_nm in o_list) {
            rec = o_list[group_nm];
            for (nm in rec) {
              row[group_nm + '_' + nm] = rec[nm];
            }
          }
          total = (Math.floor(total * 100)) + row.plan_base_price;
          row.total_amount = total;
          if (total !== (Math.floor(row.amount * 100))) {
            row.is_prorated = 'yes';
          }
          this.Table[tbl_nm] = [row];
          break;
        case 'Invoice':
          myself = (this.Epic.getInstance('User'))._getMyself();
          me = myself.users[0];
          if (me.bill_system === 0) {
            this.Table[tbl_nm] = [];
            return;
          }
          if (me.bill_system === 2) {
            row = myself.payment;
            this.Table[tbl_nm] = [row];
          } else {
            this.Table[tbl_nm] = this._getHistory();
          }
          break;
        case 'SelectedPlan':
          r = this.c_selected_plan;
          row = $.extend({
            is_selected: '',
            total: 0,
            prefix: ''
          }, this.c_selected_plan);
          if ((_ref5 = r.prefix) != null ? _ref5.length : void 0) {
            row.is_selected = 'yes';
            _log2(f, 'old row', row, 'prefix', r.prefix, 'braintree', this.c_braintree[r.prefix]);
            $.extend(row, this.c_braintree[r.prefix], this.rest.choices().bt_plans.prefix[r.prefix]);
            gblocks = row.gblock_price !== 0 ? r.extra_gblocks : 0;
            users = row.spship_price !== 0 ? r.extra_users : 0;
            row.extra_gblocks = gblocks;
            row.extra_users = users;
            row.extra_gblocks_price = gblocks * row.gblock_price;
            row.extra_users_price = users * row.spship_price;
            row.total = row.extra_gblocks_price + row.extra_users_price + row.base_price;
            row.users = 1 + row.base_spships;
          }
          this.Table[tbl_nm] = [row];
          break;
        default:
          return Billing.__super__.loadTable.call(this, tbl_nm);
      }
    };

    Billing.prototype.fistLoadData = function(oFist) {
      var card_info, f, m, now, pad, vals;
      f = "M:Billing.fistLoadData(" + (oFist.getFistNm()) + ")";
      switch (oFist.getFistNm()) {
        case 'ProfileAddon':
          return oFist.setFromDbValues(this.c_selected_plan);
        case 'CardInfo':
          card_info = this._getCardInfo();
          if ('last4' in card_info) {
            vals = {
              cc_name: card_info.cardholderName,
              cc_num: card_info.last4,
              cc_month: card_info.expirationMonth,
              cc_year: card_info.expirationYear,
              cc_zip: card_info.postalCode
            };
          } else {
            now = new Date();
            m = now.getMonth() + 1;
            pad = m < 10 ? '0' : '';
            vals = {
              cc_month: pad + (String(m)),
              cc_year: String(now.getFullYear())
            };
          }
          return oFist.setFromDbValues(vals);
        default:
          return Billing.__super__.fistLoadData.call(this, oFist);
      }
    };

    Billing.prototype._getRecommend = function() {
      var f, rest_results;
      f = "M:Billing._getRecommend";
      if (this.c_recommend) {
        return this.c_recommend;
      }
      rest_results = this.rest.get('User/me/recommendplan', f);
      this.c_recommend = rest_results;
      if (this.c_recommend.plan) {
        if (this.c_recommend.plan.min_extra_users < 0) {
          this.c_recommend.plan.min_extra_users = 0;
        }
        if (this.c_recommend.plan.min_extra_gblocks < 0) {
          this.c_recommend.plan.min_extra_gblocks = 0;
        }
      }
      return this.c_recommend;
    };

    Billing.prototype._getBilling = function() {
      var f, rec, rest_results, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
      f = "M:Billing._getBilling";
      if (this.c_billing !== false) {
        return;
      }
      this.c_billing = true;
      this.c_braintree = {};
      this.c_bank_check = {};
      this.c_bank_check_prefixed = {};
      rest_results = this.rest.get('User/me/bill_plans', f);
      if ('braintree' in rest_results) {
        _ref = rest_results.braintree;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rec = _ref[_i];
          this.c_braintree[rec.prefix] = rec;
        }
      }
      if ('bank_check' in rest_results) {
        _ref1 = rest_results.bank_check;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          rec = _ref1[_j];
          this.c_bank_check[rec.id] = rec;
        }
        _ref2 = rest_results.bank_check;
        for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
          rec = _ref2[_k];
          this.c_bank_check_prefixed[rec.prefix] = rec;
        }
      }
      this._getRecommend();
    };

    Billing.prototype._getCardInfo = function() {
      var f, rest_card, _ref;
      f = "M:Billing._getCardInfo";
      if (this.c_card_info) {
        return this.c_card_info;
      }
      rest_card = this.rest.get('User/me/account', f);
      return this.c_card_info = (_ref = rest_card.account_details) != null ? _ref : {};
    };

    Billing.prototype._getHistory = function() {
      var f, rest, _ref;
      f = "M:Billing._getHistory";
      if (this.c_history) {
        return this.c_history;
      }
      rest = this.rest.get('User/me/History', f);
      return this.c_history = (_ref = rest.history) != null ? _ref : [];
    };

    Billing.prototype._encryptFields = function(plain) {
      var braintree, f, out;
      f = "M:Billing._encryptFields";
      _log2(f, 'plain', plain);
      braintree = window.Braintree.create(window.EpicMvc.Extras.options.BtEncKey);
      out = {
        cc_exp: braintree.encrypt("" + plain.cc_month + "/" + plain.cc_year),
        cc_num: braintree.encrypt(plain.cc_num),
        cc_cvv: braintree.encrypt(plain.cc_cvv),
        cc_name: plain.cc_name,
        cc_zip: plain.cc_zip
      };
      _log2(f, 'out', out);
      return out;
    };

    Billing.prototype._checkCcExp = function(issue, oF) {
      var f, f_i, m, now, now_m, now_y, y;
      f = 'M:Billing._checkCcExp';
      f_i = oF.getFieldIssues();
      _log2(f, f_i);
      if ('CcMonth' in f_i || 'CcYear' in f_i) {
        return;
      }
      now = new Date();
      now_y = now.getFullYear();
      y = Number(oF.getHtmlFieldValue('CcYear'));
      _log2(f, 'now_y/y', now_y, y);
      if (y < now_y) {
        oF.Fb_Make(issue, 'CcYear', ['YEAR_IN_PAST']);
        return;
      }
      now_m = now.getMonth() + 1;
      m = Number(oF.getHtmlFieldValue('CcMonth'));
      _log2(f, 'now_m/m', now_m, m);
      if (y === now_y && m < now_m) {
        oF.Fb_Make(issue, 'CcYear', ['MONTH_YEAR_IN_PAST']);
      }
      return null;
    };

    return Billing;

  })(window.EpicMvc.ModelJS);

  window.EpicMvc.Model.Billing = Billing;

}).call(this);
