{$, $$, View, TextEditorView} = require 'atom'

module.exports =
class Dialog extends View
  @content: ({prompt} = {}) ->
    @div class: 'dialog overlay from-top', =>
      @label prompt, class: 'icon', outlet: 'promptText'
      @subview 'miniEditor', new TextEditorView(mini: true)
      @div class: 'error-message', outlet: 'errorMessage'

  initialize: ({prompt} = {}) ->
    @on 'core:confirm', => @onConfirm(@miniEditor.getText())
    @on 'core:cancel', => @close()
    @miniEditor.hiddenInput.on 'focusout', => @remove()
    @miniEditor.getEditor().getBuffer().on 'changed', => @showError()

  attach: (@callback) ->
    @storeFocusedElement()
    atom.workspaceView.append(this)
    @focusMiniEditor()

  close: ->
    @cancel()
    @remove()

  cancel: ->
    miniEditorFocused = @miniEditor.isFocused
    @restoreFocus() if miniEditorFocused

  showError: (message = '') ->
    @errorMessage.text(message)
    @flashError() if message

  onConfirm: (value) ->
    @callback?(undefined, value)
    @close()
    value

  storeFocusedElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.workspaceView.focus()

  focusMiniEditor: ->
    @miniEditor.focus()
