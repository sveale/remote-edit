Serializable = require 'serializable'
RemoteFile = require './remote-file'
fs = require 'fs-plus'

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

    delete: ->
      fs.unlink(@path, -> console.debug err if err?)
      if @host?
        index = @host.localFiles.indexOf(@)
        if index > -1
          @host.localFiles.splice(index)
