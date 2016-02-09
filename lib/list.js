// Generated by CoffeeScript 1.10.0
(function() {
  var List, _, defaultConfigPath, events, fs, homeDir,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  _ = require('underscore');

  fs = require('fs');

  events = require('events');

  homeDir = process.env.HOME || process.env.USERPROFILE;

  defaultConfigPath = homeDir + "/.ssh-manager.json";

  List = (function(superClass) {
    var _isValidRecord, _load, _recordToRow, _rowToRecord, _save;

    extend(List, superClass);

    _recordToRow = function(record) {
      return [String(record.name), String(record.host), String(record.user), String(record.port)];
    };

    _rowToRecord = function(row) {
      return {
        name: String(row[1]),
        host: String(row[2]),
        user: String(row[3]),
        port: Number(row[4])
      };
    };

    _isValidRecord = function(record) {
      return _.isObject(record) && ((record.name == null) || _.isString(record.name)) && _.isString(record.host) && ((record.port == null) || _.isNumber(record.port));
    };

    _load = function(file) {
      var e, error, records;
      try {
        fs.statSync(file);
      } catch (error) {
        e = error;
        return [];
      }
      records = fs.readFileSync(file, 'utf8');
      records = JSON.parse(records);
      if (!_(records).every(_isValidRecord)) {
        throw new Error("Not valid records from " + file + ".");
      }
      return records;
    };

    _save = function(file, records) {
      if (!_(records).every(_isValidRecord)) {
        throw new Error("Not valid records.");
      }
      records = JSON.stringify(records);
      return fs.writeFileSync(file, records, 'utf8');
    };

    List.property = function(prop, options) {
      return Object.defineProperty(this.prototype, prop, options);
    };

    List.property('header', {
      get: function() {
        return ["Name", "Host/IP", "User", "Port"];
      }
    });

    List.property('props', {
      get: function() {
        return ["name", "host", "user", "port"];
      }
    });

    List.property('rows', {
      get: function() {
        if (!this._rows || this._rowsInvalidated) {
          this._rows = this.records.map(_recordToRow);
          this._rowsInvalidated = false;
        }
        return this._rows;
      }
    });

    List.property('table', {
      get: function() {
        if (!this._table || this._tableInvalidated) {
          this._table = [this.header].concat(this.rows);
          this._tableInvalidated = false;
        }
        return this._table;
      }
    });

    List.property('records', {
      get: function() {
        var data;
        data = this._records;
        if (this.filter) {
          data = _(data).filter(this.filter);
        }
        if (this.sortBy) {
          data = _(data).sortBy(this.sortBy);
        }
        return data;
      },
      set: function(records) {
        if (!_(records).every(_isValidRecord)) {
          throw new Error("Not valid records.");
        }
        this._records = records;
        return this._invalidate();
      }
    });

    List.property('filter', {
      get: function() {
        if (!this._filterRegExp) {
          return null;
        }
        return (function(_this) {
          return function(value) {
            return _this._filterRegExp.test(value);
          };
        })(this);
      },
      set: function(filter) {
        var old;
        old = this._filter;
        delete this._filter;
        delete this._filterRegExp;
        if (_.isString(filter)) {
          this._filter = filter;
          this._filterRegExp = new RegExp(this._filter, 'ig');
        }
        if (this._filter !== old) {
          return this._invalidate();
        }
      }
    });

    List.property('sortBy', {
      get: function() {
        if (!this._sortBy) {
          return null;
        }
        return (function(_this) {
          return function(value) {
            return value[_this._sortBy];
          };
        })(this);
      },
      set: function(sortBy) {
        var old;
        old = this._sortBy;
        delete this._sortBy;
        if (_.isString(sortBy) && _(this.props).include(sortBy)) {
          this._sortBy = sortBy;
        }
        if (this._sortBy !== old) {
          return this._invalidate();
        }
      }
    });

    List.property('length', {
      get: function() {
        return this._records.length;
      }
    });

    List.prototype._invalidate = function() {
      this._rowsInvalidated = true;
      this._tableInvalidated = true;
      return this.emit('invalidated');
    };

    function List(configFile) {
      this.configFile = configFile != null ? configFile : defaultConfigPath;
      this.records = _load(this.configFile);
    }

    List.prototype.add = function(record) {
      if (!_isValidRecord(record)) {
        throw new Error("Not valid record.");
      }
      this._records.push(record);
      _save(this.configFile, this._records);
      return this._invalidate();
    };

    List.prototype.remove = function(index) {
      if (index >= 0 && index < this._records.length) {
        this._records.splice(index, 1);
        _save(this.configFile, this._records);
        return this._invalidate();
      }
    };

    List.prototype.getArgs = function(index) {
      var host, record;
      record = this._records[index];
      if (!record) {
        throw new Error("Not found record.");
      }
      if (!_isValidRecord(record)) {
        throw new Error("Not valid record.");
      }
      host = record.host;
      if (record.user) {
        host = record.user + "@" + host;
      }
      if (record.port === 22) {
        return [host];
      } else {
        return [host, "-p", String(record.port)];
      }
    };

    return List;

  })(events.EventEmitter);

  module.exports = List;

}).call(this);