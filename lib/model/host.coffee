Serializable = require 'serializable'
async = require 'async'
{Emitter, Subscriber} = require 'emissary'

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
              #console.debug 'Saved event called on file that is connected to this host'
              @writeFile(localFile, buffer.getText(), null)
              @emit('localFileSaved')
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
