{$$, SelectListView} = require 'atom'

async = require 'async'
Q = require 'q'
_ = require 'underscore-plus'

FileEditorView = require './file-editor-view'
LocalFile = require '../model/local-file'

module.exports =
  class OpenFilesView extends SelectListView
    initialize: (@ipdw) ->
      super
      @addClass('overlay from-top open-files-view')
      @createItemsFromIpdw()
      @listenForEvents()
      @subscribe @ipdw, 'contents-changed', => @createItemsFromIpdw()

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    getFilterKey: ->
      return "name"

    viewForItem: (localFile) ->
      $$ ->
        @li class: 'local-file', "#{localFile.host.username}@#{localFile.host.hostname}:#{localFile.host.port}#{localFile.remoteFile.path}"

    confirmed: (localFile) ->
      uri = "remote-edit://localFile/?path=#{encodeURIComponent(localFile.path)}&title=#{encodeURIComponent(localFile.name)}"
      atom.workspace.open(uri, split: 'left').then((editorView) ->
        editorView.localFile = localFile
        editorView.host = localFile.host
        )

    listenForEvents: ->
      @command 'openfilesview:delete', =>
        item = @getSelectedItem()
        if item?
          @items = _.reject(@items, ((val) -> val == item))
          item.delete()
          @setLoading()

    createItemsFromIpdw: ->
      @ipdw.data.then((data) =>
        localFiles = []
        async.each(data.hostList, ((host, callback) ->
          async.each(host.localFiles, ((file, callback) ->
            file.host = host
            localFiles.push(file)
            ), ((err) -> console.err err if err?))
          ), ((err) -> console.err err if err?))
        @setItems(localFiles)
      )
