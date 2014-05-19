{$$, SelectListView, EditorView} = require 'atom'

FilesView = require './files-view'
SftpHost = require '../model/sftp-host'
FtpHost = require '../model/ftp-host'

module.exports =
  class HostView extends SelectListView
    initialize: (@listOfItems) ->
      super
      @addClass('overlay from-top')
      @setItems(@listOfItems)

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    cancel: ->
      @hide()

    getFilterKey: ->
      return "hostname"

    viewForItem: (item) ->
      $$ ->
        @li class: 'two-lines', =>
          @div class: 'primary-line', "#{item.username}@#{item.hostname}:#{item.port}:#{item.directory}"
          if item instanceof SftpHost
            @div class: "secondary-line", "Type: SFTP"
          else if item instanceof FtpHost
            @div class: "secondary-line", "Type: FTP"
          else
            @div class: "secondary-line", "Type: UNDEFINED"

    confirmed: (item) ->
      if item instanceof SftpHost
        filesView = new FilesView(item)
        filesView.attach()
      else if item instanceof FtpHost
        throw new Error("Not implemented!")
      else
        throw new Error("Not implemented!")
