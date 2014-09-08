Serializable = require 'serializable'

Path = require 'path'

module.exports =
  class RemoteFile
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    constructor: (@path, @isFile, @isDir, @size, @permissions, @lastModified) ->
      @name = Path.basename(@path)

    isHidden: (callback) ->
      callback(!(@name[0] == "." && @name.length > 2))

    serializeParams: ->
      {@path, @isFile, @isDir, @size, @permissions, @lastModified}
