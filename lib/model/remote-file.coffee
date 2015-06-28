Serializable = require 'serializable'

Path = require 'path'

module.exports =
  class RemoteFile
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    constructor: (@path, @isFile, @isDir, @isLink, @size, @permissions, @lastModified) ->
      @name = Path.basename(@path)
      @dirName = Path.dirname(@path)

    isHidden: (callback) ->
      callback(!(@name[0] == "." && @name.length > 2))

    serializeParams: ->
      {@path, @isFile, @isDir, @isLink, @size, @permissions, @lastModified}
