{$$, SelectListView} = require 'atom'
_ = require 'underscore-plus'

FilesView = require './files-view'
SftpHost = require '../model/sftp-host'
FtpHost = require '../model/ftp-host'

module.exports =
  class HostView extends SelectListView

    initialize: (@listOfItems = []) ->
      super
      @addClass('overlay from-top hostview')
      @setItems(@listOfItems)
      @listenForEvents()

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    getFilterKey: ->
      return "hostname"

    viewForItem: (item) ->
      $$ ->
        @li class: 'two-lines', =>
          @div class: 'primary-line', "#{item.username}@#{item.hostname}:#{item.port}:#{item.directory}"
          if item instanceof SftpHost
            authType = "not set"
            if item.usePassword and (item.password == "" or item.password == '' or !item.password?)
              authType = "password (not set)"
            else if item.usePassword
              authType = "password (set)"
            else if item.usePrivateKey
              authType = "key"
            else if item.useAgent
              authType = "agent"
            @div class: "secondary-line", "Type: SFTP, Open files: #{item.localFiles.length}, Auth: " + authType
          else if item instanceof FtpHost
            authType = "not set"
            if item.usePassword and (item.password == "" or item.password == '' or !item.password?)
              authType = "password (not set)"
            else
              authType = "password (set)"
            @div class: "secondary-line", "Type: FTP, Open files: #{item.localFiles.length}, Auth: " + authType
          else
            @div class: "secondary-line", "Type: UNDEFINED"

    confirmed: (item) ->
      @cancel()
      filesView = new FilesView(item)
      filesView.attach()

    listenForEvents: ->
      @command 'hostview:delete', =>
        item = @getSelectedItem()
        if item?
          @items = _.reject(@items, ((val) => val == item))
          item.delete()
          @populateList()
          @setLoading()
