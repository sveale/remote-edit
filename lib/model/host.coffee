Serializable = require 'serializable'
async = require 'async'
{Emitter, Subscriber} = require 'emissary'
hash = require 'string-hash'

module.exports =
  class Host
    Serializable.includeInto(this)

    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    constructor: (@hostname, @directory, @username, @port, @localFiles = []) ->
      atom.project.eachBuffer (buffer) =>
        @subscribe buffer, 'will-be-saved', =>
          async.detect(@localFiles, ((localFile, callback) -> callback(localFile.path == buffer.getUri())), (localFile) =>
            if localFile?
              @emit 'info', {message: "Local version of remote file #{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path} has been saved", className: 'text-info'}
              @writeFile(localFile, buffer.getText(), null)
          )

    getConnectionString: ->
      throw new Error("Function getConnectionString() needs to be implemented by subclasses!")

    connect: (callback) ->
      throw new Error("Function connect(callback) needs to be implemented by subclasses!")

    getFilesMetadata: (path, callback) ->
      throw new Error("Function getFiles(Callback) needs to be implemented by subclasses!")

    getFileData: (file, callback) ->
      throw new Error("see subclass")

    serializeParams: ->
      throw new Error("Must be implemented in subclass!")

    writeFile: (file, text, callback) ->
      throw new Error("Must be implemented in subclass!")

    hashCode: ->
      hash(@hostname + @directory + @username + @port)

    addLocalFile: (localFile) ->
      @localFiles.push(localFile)
      @emit 'localFileAdded', localFile
