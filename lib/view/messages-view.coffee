{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

module.exports =
  class MessagesView
    closeMessagesTimer: undefined

    constructor: (title) ->
      @messages = new MessagePanelView({title: "#{title}"})

    postMessage: (data) ->
      @messages?.attach()
      @messages?.add(new PlainMessageView(data))

      closeMessages = =>
        @messages.clear()
        @messages.close()

      clearTimeout(closeMessagesTimer) if closeMessagesTimer?
      closeMessagesTimer = setTimeout(closeMessages, atom.config.get('remote-edit.messagePanelTimeout'))

    destroy: ->
      clearTimeout(closeMessagesTimer) if closeMessagesTimer?
      @messages.clear()
      @messages.close()
