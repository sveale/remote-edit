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
            @div class: "secondary-line", "Type: SFTP, Open files: #{item.localFiles.length}, Auth: " +
              if item.usePassword
                "password" +
                if item.password == "" or item.password == '' or !item.password?
                  " (not set)"
              else if item.usePrivateKey
                "key"
              else if item.useAgent
                "agent"
              else
                "undefined"
          else if item instanceof FtpHost
            @div class: "secondary-line", "Type: FTP, Open files: #{item.localFiles.length}, Auth: password" +
            if item.password == "" or item.password == '' or !item.password?
              " (not set)"
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
