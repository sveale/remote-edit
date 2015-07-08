Serializable = require 'serializable'
RemoteFile = require './remote-file'
Host = require './host'
fs = require 'fs-plus'

module.exports =
  class LocalFile
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    constructor: (@path, @remoteFile, @dtime, @host = null) ->
      @name = @remoteFile.name

    serializeParams: ->
      {
        @path
        remoteFile: @remoteFile.serialize()
        @dtime
      }

    deserializeParams: (params) ->
      params.remoteFile = RemoteFile.deserialize(params.remoteFile)
      params

    delete: ->
      fs.unlink(@path, -> console.error err if err?)
      @host?.removeLocalFile(this)
