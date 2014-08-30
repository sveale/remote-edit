Serializable = require 'serializable'
{Subscriber, Emitter} = require 'emissary'

MessagesView = require '../view/messages-view'
FileEditorView = require '../view/file-editor-view'

# Defer requiring
Host = null
FtpHost = null
SftpHost = null
LocalFile = null
RemoteFile = null
_ = null

module.exports =
  class InterProcessData
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    messages: new MessagesView("Remote edit")

    constructor: (@hostList = []) ->
      for host in @hostList
        @addSubscriptionToHost(host)

      if atom.config.get 'remote-edit.messagePanel'
        for pane in atom.workspaceView.getPaneViews()
            for item in pane.getItems()
              if item instanceof FileEditorView
                _ ?= require 'underscore-plus'
                unless _.contains(@hostList, item.host)
                  @subscribe item.host, 'info', (info) => @messages.postMessage(info)

    serializeParams: ->
      hostList: JSON.stringify(host.serialize() for host in @hostList)

    deserializeParams: (params) ->
      tmpArray = []
      if params.hostList?
        Host ?= require './host'
        FtpHost ?= require './ftp-host'
        SftpHost ?= require './sftp-host'
        LocalFile ?= require './local-file'
        RemoteFile ?= require './remote-file'
        tmpArray.push(Host.deserialize(host)) for host in JSON.parse(params.hostList)
      params.hostList = tmpArray
      params

    addSubscriptionToHost: (host) ->
      @subscribe host, 'changed', => @emit 'contents-changed'
      @subscribe host, 'delete', =>
        @hostList = _.reject(@hostList, ((val) -> val == host))
        @emit 'contents-changed'

      if atom.config.get 'remote-edit.messagePanel'
        @subscribe host, 'info', (info) => @messages.postMessage(info)
