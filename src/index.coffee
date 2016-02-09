spawn = require('child_process').spawn
blessed = require 'blessed'
List = require './list'
form = require './form'

list = new List

screen = blessed.screen
  smartCSR: true

table = blessed.listtable
  parent: screen

  mouse : true
  keys  : true
  vi    : true

  left  : 0
  top   : 0

  width : '100%'
  height: '100%'

  noCellBorders: true
  align : 'left'
  rows  : list.table

  style:
    header:
      bold: true
      fg  : 'black'
      bg  : 'white'
    cell:
      selected:
        bg: 'blue'

table.on 'select', (element, index) ->
  try
    args = list.getArgs(index - 1)
    screen.destroy()
    console.log ['exec >', 'ssh'].concat(args).join(' ')
    spawn('ssh', args, detached: true, stdio: 'inherit')
  catch e
    console.error e #TODO

form = form(screen)
form.on 'submit', (data = {}) ->
  try
    list.add
      name: String(data.name) || null
      host: String(data.host) || null
      user: String(data.user) || null
      port: Number(data.port) || 22
  catch e
    console.error e #TODO

# Key events
screen.key ['delete'], ->
  try
    list.remove table.selected - 1
    screen.render()
  catch e
    console.error e #TODO

screen.key ['C-a'], ->
  form.toggle()

screen.key ['escape'], ->
  if form.hidden
    screen.destroy()
  else
    form.toggle()

screen.key ['C-c', 'q'], ->
  screen.destroy()

# Init
list.on 'invalidated', ->
  selected = table.selected
  table.setRows list.table
  table.select selected
  screen.render()

table.focus()
screen.render()
