blessed = require 'blessed'

createInput = (form, label, name, top) ->
  blessed.box
    parent: form

    height: 1
    width : 5

    align  : 'left'
    content: label

    top : top
    left: 0

    style:
      bg: 'blue'
      fg: 'white'

  blessed.textbox
    parent: form
    name  : name

    mouse : true
    keys  : true

    inputOnFocus: true

    height: 1
    width : 20

    top : top
    left: 5

    style :
      bg: 'white'
      fg: 'black'


module.exports = (screen) ->
  form = blessed.form
    screen: screen
    parent: screen
    border: 'line'
    hidden: true

    width : 27
    height: 11

    top : 'center'
    left: 'center'

    label: 'Add record'

    keys : true
    mouse: true
    vi   : true

    style:
      bg: 'blue'
      border:
        bg: 'blue'
        fg: 'white'
      label:
        bg: 'blue'
        bold: true

  name = createInput(form, 'Name', 'name', 0)
  host = createInput(form, 'Host', 'host', 2)
  user = createInput(form, 'User', 'user', 4)
  port = createInput(form, 'Port', 'port', 6)

  submit = blessed.button
    parent: form
    name  : 'submit'

    mouse : true
    keys  : true

    height: 1
    width : 'shrink'

    left  : 'center'
    top   : 8

    content: 'Submit'
    style:
      fg: 'white'
      bg: 'green'
      focus: bg: 'red'

  form.toggle = ->
    if @hidden
      @screen.saveFocus()
      @reset()
      @show()
      @setFront()
      @focusFirst()
    else
      @hide()
      @screen.restoreFocus()
    @screen.render()

  submit.on 'press', ->
    form.submit()

  form.on 'submit', ->
    form.toggle()

  form.on 'cancel', ->
    form.toggle()

  return form
