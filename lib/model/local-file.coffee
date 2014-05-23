Serializable = require 'serializable'
RemoteFile = require './remote-file'

module.exports =
  class LocalFile
    Serializable.includeInto(this)

    constructor: (@path, @remoteFile, @host = null) ->
      @name = @remoteFile.name

    serializeParams: ->
      {
        @path
        remoteFile: @remoteFile.serialize()
      }

    deserializeParams: (params) ->
      params.remoteFile = RemoteFile.deserialize(params.remoteFile)
      params
