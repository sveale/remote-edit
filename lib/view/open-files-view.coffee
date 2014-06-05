{$$, SelectListView} = require 'atom'

async = require 'async'
Q = require 'q'
_ = require 'underscore-plus'

module.exports =
  class OpenFilesView extends SelectListView
    initialize: (@listOfItems) ->
      super
      @addClass('overlay from-top openfilesview')
      @setItems(@listOfItems)
      @listenForEvents()

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    getFilterKey: ->
      return "name"

    viewForItem: (localFile) ->
      $$ ->
        @li class: 'localfile', "#{localFile.host.username}@#{localFile.host.hostname}:#{localFile.host.port}#{localFile.remoteFile.path}"

    confirmed: (localFile) ->
      uri = "remote-edit://localFile/#{localFile.path}"
      atom.workspace.open(uri, split: 'left').then((editorView) =>
        editorView.localFile = localFile
        editorView.host = localFile.host
        )

    listenForEvents: ->
      @command 'openfilesview:delete', =>
        item = @getSelectedItem()
        if item?
          @items = _.reject(@items, ((val) => val == item))
          item.delete()
          @populateList()
          @setLoading()
