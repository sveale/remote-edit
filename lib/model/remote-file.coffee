module.exports =
  class RemoteFile
    constructor: (@path, @isFile, @isDir, @size, @permissions, @lastModified) ->
      @name = @getName()

    isHidden: (callback) ->
      callback(!(@name[0] == "." && @name.length >2))

    getName: ->
      arr = @path.split("/")
      return arr[arr.length - 1]
