Serializable = require 'serializable'
RemoteFile = require './remote-file'

module.exports =
  class LocalFile
    Serializable.includeInto(this)
    #Emitter.includeInto(this)

    constructor: (@path, @remoteFile) ->

    serializeParams: ->
      {
        @path
        remoteFile: @remoteFile.serialize()
      }

    deserializeParams: (params) ->
      params.remoteFile = RemoteFile.deserialize(params.remoteFile)
      params
