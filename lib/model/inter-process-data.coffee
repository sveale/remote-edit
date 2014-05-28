Serializable = require 'serializable'

Host = require './host'

module.exports =
  class InterProcessData
    Serializable.includeInto(this)

    constructor: (@hostList = []) ->

    serializeParams: ->
      hostList: JSON.stringify(host.serialize() for host in @hostList)

    deserializeParams: (params) ->
      tmpArray = []
      tmpArray.push(Host.deserialize(host)) for host in JSON.parse(params.hostList)
      params.hostList = tmpArray
      params
