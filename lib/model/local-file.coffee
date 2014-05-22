Serializable = require 'serializable'

module.exports =
  class LocalFile
    Serializable.includeInto(this)

    constructor: (@path, @remoteFile) ->

    serializeParams: ->
      {
        @path
        remoteFile: @remoteFile.serialize()
      }

    deserializeParams: (params) ->
      params
