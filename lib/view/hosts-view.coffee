{$, $$, SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable, Emitter} = require 'atom'
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
      @addClass('hosts-view')

      @disposables = new CompositeDisposable
      @disposables.add @ipdw.onDidChange => @createItemsFromIpdw()

      @listenForEvents()

    destroy: ->
      @panel.destroy() if @panel?
      @disposables.dispose()

    cancelled: ->
      @hide()
      @destroy()

    toggle: ->
      if @panel?.isVisible()
        @cancel()
      else
        @show()

    show: ->
      @panel ?= atom.workspace.addModalPanel(item: this)
      @panel.show()

      @storeFocusedElement()

      @focusFilterEditor()

    hide: ->
      @panel?.hide()

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
      filesView.connect()
      filesView.toggle()

    listenForEvents: ->
      @disposables.add atom.commands.add 'atom-workspace', 'hostview:delete', =>
        item = @getSelectedItem()
        if item?
          item.delete()
          @setLoading()
      @disposables.add atom.commands.add 'atom-workspace', 'hostview:edit', =>
        item = @getSelectedItem()
        if item?
          hostView = new HostView(item)
          hostView.toggle()
          @cancel()

    createItemsFromIpdw: ->
      @ipdw.getData().then((resolved) => @setItems(resolved.hostList))
