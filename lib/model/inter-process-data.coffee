Serializable = require 'serializable'
{Subscriber, Emitter} = require 'emissary'
_ = require 'underscore-plus'
util = require 'util'

Host = require './host'
FtpHost = require './ftp-host'
SftpHost = require './sftp-host'
LocalFile = require './local-file'
RemoteFile = require './remote-file'

MessagesView = require '../view/messages-view'

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

    serializeParams: ->
      hostList: JSON.stringify(host.serialize() for host in @hostList)

    deserializeParams: (params) ->
      tmpArray = []
      tmpArray.push(Host.deserialize(host)) for host in JSON.parse(params.hostList)
      params.hostList = tmpArray
      params

    addSubscriptionToHost: (host) ->
      @subscribe host, 'changed', => @emit 'contents-changed'
      @subscribe host, 'delete', =>
        @hostList = _.reject(@hostList, ((val) -> val == host))
        @emit 'contents-changed'
      @subscribe host, 'info', (info) => @messages.postMessage(info)


      #  async.each(data.hostList, ((item) => @subscribe item, 'info', (info) => @postMessage(info)), null)
