module.exports =
  class RemoteFile
    constructor: (@name, @isFile, @isDir, @size, @permissions, @lastModified) ->

    isHidden: (callback) ->
      callback(!(@name[0] == "." && @name.length >2))
