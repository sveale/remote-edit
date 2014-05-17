{$$, SelectListView, EditorView} = require 'atom'

SftpFileView = require './sftp-file-view'

module.exports =
  class RemoteEditHostView extends SelectListView
    initialize: (@listOfItems) ->
      super
      @addClass('overlay from-top')
      @setItems((['Add new'].concat @listOfItems))

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    cancel: ->
      @hide()

    viewForItem: (item) ->
      $$ ->
        @li =>
          @raw item

    confirmed: (item) ->
      if (item == 'Add new')
        # Need to implement something here...
      else
        connOpts = {host: item, username: 'sverre'}
        sftpFileView = new SftpFileView('/', connOpts)
        sftpFileView.attach()
