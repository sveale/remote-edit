{$, $$, View, TextEditorView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

module.exports =
class Dialog extends View
  @content: ({prompt} = {}) ->
    @div class: 'dialog', =>
      @label prompt, class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: ({iconClass} = {}) ->
    @promptText.addClass(iconClass) if iconClass

    @disposables = new CompositeDisposable
    @disposables.add atom.commands.add 'atom-workspace',
      'core:confirm': => @onConfirm(@miniEditor.getText())
      'core:cancel': (event) =>
        @cancel()
        event.stopPropagation()

    @miniEditor.getModel().onDidChange => @showError()
    @miniEditor.on 'blur', => @cancel()

  onConfirm: (value) ->
    @callback?(undefined, value)
    @cancel()
    value

  showError: (message='') ->
    @errorMessage.text(message)
    @flashError() if message

  destroy: ->
    @disposables.dispose()

  cancel: ->
    @cancelled()
    @restoreFocus()
    @destroy()

  cancelled: ->
    @hide()

  toggle: (@callback) ->
    if @panel?.isVisible()
      @cancel()
    else
      @show()

  show: () ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @storeFocusedElement()
    @miniEditor.focus()

  hide: ->
    @panel?.hide()

  storeFocusedElement: ->
    @previouslyFocusedElement = $(document.activeElement)

  restoreFocus: ->
    @previouslyFocusedElement?.focus()
