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
      @data = @load()
      @subscribe @file, 'contents-changed', => @data = @load()

    load: ->
      deferred = Q.defer()
      @file.read().then((content) ->
        deferred.resolve(InterProcessData.deserialize(JSON.parse(content)) ? new InterProcessData([]))
      )

      deferred.promise.then (data) =>
        @subscribe data, 'contents-changed', => @commit()
        @emit 'contents-changed'

      deferred.promise


    commit: ->
      @data.then (resolvedData) =>
        @file.write(JSON.stringify(resolvedData.serialize()))
