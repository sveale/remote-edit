Serializable = require 'serializable'
async = require 'async'
{Emitter, Subscriber} = require 'emissary'
hash = require 'string-hash'
_ = require 'underscore-plus'
osenv = require 'osenv'

module.exports =
  class Host
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    constructor: (@alias = null, @hostname, @directory = "/", @username = osenv.user(), @port, @localFiles = [], @usePassword) ->

    getConnectionString: ->
      throw new Error("Function getConnectionString() needs to be implemented by subclasses!")

    connect: (callback, connectionOptions = {}) ->
      throw new Error("Function connect(callback) needs to be implemented by subclasses!")

    close: (callback) ->
      throw new Error("Needs to be implemented by subclasses!")

    getFilesMetadata: (path, callback) ->
      throw new Error("Function getFiles(Callback) needs to be implemented by subclasses!")

    getFileData: (file, callback) ->
      throw new Error("see subclass")

    serializeParams: ->
      throw new Error("Must be implemented in subclass!")

    writeFile: (file, text, callback) ->
      throw new Error("Must be implemented in subclass!")

    isConnected: ->
      throw new Error("Must be implemented in subclass!o")

    hashCode: ->
      hash(@hostname + @directory + @username + @port)

    addLocalFile: (localFile) ->
      @localFiles.push(localFile)
      @emit 'changed', localFile

    removeLocalFile: (localFile) ->
      @localFiles = _.reject(@localFiles, ((val) -> val == localFile))
      @emit 'changed', localFile

    delete: ->
      for file in @localFiles
        file.delete()
      @emit 'delete', this

    invalidate: ->
      @emit 'changed'
