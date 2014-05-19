{$$, SelectListView, EditorView} = require 'atom'

SftpFilesView = require './sftp-files-view'

module.exports =
  class HostView extends SelectListView
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

    addNewItem: ->
      throw new Error("Not implemented!")

    getValuesFromItem: (item) ->
      regexp = /[@:]+/
      item.split(regexp)
