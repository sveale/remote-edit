{$$, SelectListView} = require 'atom'

async = require 'async'

module.exports =
  class OpenFilesView extends SelectListView

    initialize: (@listOfItems) ->
      super
      @addClass('overlay from-top')
      @setItems(@listOfItems)

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    getFilterKey: ->
      return "name"

    viewForItem: (localFile) ->
      $$ ->
        @li "#{localFile.host.username}@#{localFile.host.hostname}:#{localFile.host.port}#{localFile.remoteFile.path}"

    confirmed: (localFile) ->
      uri = "remote-edit://editor/#{localFile.path}"
      atom.workspace.open(uri, split: 'left')
