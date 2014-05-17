module.exports =
  class RemoteFile
    constructor: (@name, @isFile, @isDir, @size, @permissions, @lastModified) ->
