{$, $$, SelectListView} = require 'atom'
_ = require 'underscore-plus'

FilesView = require './files-view'
HostView = require './host-view'

SftpHost = require '../model/sftp-host'
FtpHost = require '../model/ftp-host'

module.exports =
  class HostsView extends SelectListView
    initialize: (@ipdw) ->
      super
      @createItemsFromIpdw()
      @addClass('overlay from-top hosts-view')
      @listenForEvents()
      @subscribe @ipdw, 'contents-changed', => @createItemsFromIpdw()


    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    getFilterKey: ->
      return "hostname"

    viewForItem: (item) ->
      keyBindings = @keyBindings

      $$ ->
        @li class: 'two-lines', =>
          @div class: 'primary-line', =>
            @span class: 'inline-block highlight', "#{item.alias}" if item.alias?
            @span class: 'inline-block', "#{item.username}@#{item.hostname}:#{item.port}:#{item.directory}"
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
          @items = _.reject(@items, ((val) -> val == item))
          item.delete()
          @populateList()
          @setLoading()
      @command 'hostview:edit', =>
        item = @getSelectedItem()
        if item?
          @cancel()
          hostView = new HostView(item)
          hostView.attach()

    createItemsFromIpdw: ->
      @ipdw.data.then((data) => @setItems(data.hostList))
