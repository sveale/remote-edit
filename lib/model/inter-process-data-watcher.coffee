{File} = require 'pathwatcher'
{Subscriber, Emitter} = require 'emissary'
Q = require 'q'
util = require 'util'

InterProcessData = require './inter-process-data'

module.exports =
  class InterProcessDataWatcher
    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    constructor: (@filePath) ->
      @file = new File(@filePath)
      @subscribe @file, 'contents-changed', => @data = @load()
      @data = @load()

    load: ->
      deferred = Q.defer()
      @file.read().then((content) ->
        deferred.resolve(InterProcessData.deserialize(JSON.parse(content)))
      )

      deferred.promise.then (data) =>
        @subscribe data, 'contents-changed', =>@commit
        @emit 'contents-changed'

      deferred.promise


    commit: ->
      @data.then (data) =>
        @file.write(JSON.stringify(data.serialize()))
