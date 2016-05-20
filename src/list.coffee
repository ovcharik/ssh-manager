_      = require 'underscore'
fs     = require 'fs'
events = require 'events'
path   = require 'path'

homeDir = process.env.HOME || process.env.USERPROFILE
defaultConfigPath = path.join homeDir, ".ssh-manager.json"

class List extends events.EventEmitter
  _recordToRow = (record) ->
    [String(record.name), String(record.host), String(record.user), String(record.port)]

  _rowToRecord = (row) ->
    name: String(row[1]), host: String(row[2]), user: String(row[3]), port: Number(row[4])

  _isValidRecord = (record) ->
    (
      _.isObject(record) and
      (not record.name? or _.isString(record.name)) and
      _.isString(record.host) and #TODO regex
      (not record.port? or _.isNumber(record.port))
    )

  _load = (file) ->
    try
      fs.statSync(file)
    catch e
      return []
    records = fs.readFileSync file, 'utf8'
    records = JSON.parse records
    throw new Error("Not valid records from #{file}.") unless _(records).every(_isValidRecord)
    records

  _save = (file, records) ->
    throw new Error("Not valid records.") unless _(records).every(_isValidRecord)
    records = JSON.stringify(records, null, 2)
    fs.writeFileSync file, records, 'utf8'


  @property: (prop, options) ->
    Object.defineProperty @prototype, prop, options

  @property 'header', get: ->
    ["Name", "Host/IP", "User", "Port"]

  @property 'props', get: ->
    ["name", "host", "user", "port"]

  @property 'rows', get: ->
    if not @_rows or @_rowsInvalidated
      @_rows = @records.map(_recordToRow)
      @_rowsInvalidated = false
    return @_rows

  @property 'table', get: ->
    if not @_table or @_tableInvalidated
      @_table = [@header].concat @rows
      @_tableInvalidated = false
    return @_table

  @property 'records',
    get: ->
      data = @_records
      data = _(data).filter(@filter) if @filter
      data = _(data).sortBy(@sortBy) if @sortBy
      return data
    set: (records) ->
      throw new Error("Not valid records.") unless _(records).every(_isValidRecord)
      @_records = records
      @_invalidate()

  @property 'filter',
    get: ->
      return null unless @_filterRegExp
      (value) => @_filterRegExp.test(value)
    set: (filter) ->
      old = @_filter
      delete @_filter
      delete @_filterRegExp
      if _.isString filter
        @_filter = filter
        @_filterRegExp = new RegExp @_filter, 'ig'
      if @_filter != old
        @_invalidate()

  @property 'sortBy',
    get: ->
      return null unless @_sortBy
      (value) => value[@_sortBy]
    set: (sortBy) ->
      old = @_sortBy
      delete @_sortBy
      if _.isString(sortBy) and _(@props).include(sortBy)
        @_sortBy = sortBy
      if @_sortBy != old
        @_invalidate()

  @property 'length', get: -> @_records.length


  _invalidate: ->
    @_rowsInvalidated  = true
    @_tableInvalidated = true
    @emit 'invalidated'


  constructor: (@configFile = defaultConfigPath) ->
    @records = _load(@configFile)

  add: (record) ->
    throw new Error("Not valid record.") unless _isValidRecord(record)
    @_records.push record
    _save @configFile, @_records
    @_invalidate()

  remove: (index) ->
    if index >= 0 and index < @_records.length
      @_records.splice(index, 1)
      _save @configFile, @_records
      @_invalidate()

  getArgs: (index) ->
    record = @_records[index]
    throw new Error("Not found record.") unless record
    throw new Error("Not valid record.") unless _isValidRecord(record)
    host = record.host
    host = "#{record.user}@#{host}" if record.user
    if record.port == 22
      return [host]
    else
      return [host, "-p", String(record.port)]


module.exports = List
