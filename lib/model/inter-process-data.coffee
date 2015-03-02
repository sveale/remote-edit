Serializable = require 'serializable'
{CompositeDisposable, Emitter} = require 'atom'

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

    constructor: (@hostList) ->
      @emitter = new Emitter
      @disposables = new CompositeDisposable
      @load(@hostList)

    destroy: ->
      @disposables.dispose()
      @emitter.dispose()
      for item in @hostList
        item.destroy()
      @hostList = []

    onDidChange: (callback) ->
      @emitter.on 'did-change', callback

    load: (@hostList = []) ->
      for host in @hostList
        @addSubscriptionToHost(host)

      if atom.config.get 'remote-edit.messagePanel'
        MessagesView ?= require '../view/messages-view'
        @messages ?= new MessagesView("Remote edit")

        RemoteEditEditor ?= require '../model/remote-edit-editor'

        @disposables.add atom.workspace.observeTextEditors((editor) =>
          if editor instanceof RemoteEditEditor
            # If a host emits information ('info'), forward this to @messages
            @disposables.add editor.host.onInfo (info) => @messages.postMessage(info)
        )

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
      @disposables.add host.onDidChange =>
        @emitter.emit 'did-change'
      @disposables.add host.onDidDelete (host) =>
        _ ?= require 'underscore-plus'
        host.destroy()
        @hostList = _.reject(@hostList, ((val) -> val == host))
        @emitter.emit 'did-change'

      if atom.config.get 'remote-edit.messagePanel'
        @disposables.add host.onInfo (info) => @messages.postMessage(info)
