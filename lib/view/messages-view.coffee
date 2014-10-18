{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

module.exports =
  class MessagesView
    constructor: (title) ->
      @messages = new MessagePanelView({title: "#{title}"})

    postMessage: (data) ->
      @messages?.attach()
      @messages?.add(new PlainMessageView(data))

      closeCallback = =>
        @close()

      clearTimeout(@closeTimer) if @closeTimer?

      @closeTimer = setTimeout(closeCallback, atom.config.get('remote-edit.messagePanelTimeout'))

    close: ->
      @messages.clear()
      @messages.close()

    destroy: ->
      clearTimeout(@closeTimer) if @closeTimer?
      @messages.clear()
      @messages.close()
