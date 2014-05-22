Serializable = require 'serializable'

module.exports =
  class RemoteFile
    Serializable.includeInto(this)

    constructor: (@path, @isFile, @isDir, @size, @permissions, @lastModified) ->
      @name = @getName()

    isHidden: (callback) ->
      callback(!(@name[0] == "." && @name.length >2))

    getName: ->
      arr = @path.split("/")
      return arr[arr.length - 1]

    serializeParams: ->
      {@path, @isFile, @isdir, @size, @permissions, @lastModified}
