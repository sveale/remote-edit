Serializable = require 'serializable'
{CompositeDisposable, Emitter} = require 'event-kit'

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
      @hostSubscriptions ?= new CompositeDisposable
      @load(@hostList)

    load: (@hostList = []) ->
      for host in @hostList
        @addSubscriptionToHost(host)

      if atom.config.get 'remote-edit.messagePanel'
        MessagesView ?= require '../view/messages-view'
        @messages ?= new MessagesView("Remote edit")

        RemoteEditEditor ?= require '../model/remote-edit-editor'

        @workspaceSubscription ?= atom.workspace.observeTextEditors((editor) =>
          if editor instanceof RemoteEditEditor
            if editor.host.getSubscriptionCount() < 1
              # If a host emits information ('info'), forward this to @messages
              hostSubscriptions.add editor.host.onInfo (info) => @messages.postMessage(info)
        )

    # Remove all subscriptions to hosts and atom.workspace
    reset: ->
      @hostSubscriptions.dispose()
      @workspaceSubscription.dispose()

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
      hostSubscriptions.add host.onDidChange => #emit
      hostSubscriptions.add host.onDidDelete (host) =>
        _ ?= require 'underscore-plus'
        @hostList = _.reject(@hostList, ((val) -> val == host))
        @emitter.emit 'did-change-contents'

      if atom.config.get 'remote-edit.messagePanel'
        hostSubscriptions.add host.onInfo (info) => @messages.postMessage(info)
