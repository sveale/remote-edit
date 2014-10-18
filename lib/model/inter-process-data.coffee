Serializable = require 'serializable'
{Subscriber, Emitter} = require 'emissary'

# Defer requiring
Host = null
FtpHost = null
SftpHost = null
LocalFile = null
RemoteFile = null
_ = null
MessagesView = null
RemoteEditEditor = null

module.exports =
  class InterProcessData
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    constructor: (@hostList) ->
      @load(@hostList)

    load: (@hostList = []) ->
      for host in @hostList
        @addSubscriptionToHost(host)

      if atom.config.get 'remote-edit.messagePanel'
        MessagesView ?= require '../view/messages-view'
        @messages ?= new MessagesView("Remote edit")

        RemoteEditEditor ?= require '../model/remote-edit-editor'

        atom.workspace.observeTextEditors((editor) =>
          if editor instanceof RemoteEditEditor
            if editor.host.getSubscriptionCount() < 1
              @subscribe editor.host, 'info', (info) => @messages.postMessage(info)
        )

    reset: ->
      for host in @hostList
        @unsubscribe host
      @unsubscribe atom.workspace
      delete @hostList

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
        _ ?= require 'underscore-plus'
        @hostList = _.reject(@hostList, ((val) -> val == host))
        @emit 'contents-changed'

      if atom.config.get 'remote-edit.messagePanel'
        @subscribe host, 'info', (info) => @messages.postMessage(info)
