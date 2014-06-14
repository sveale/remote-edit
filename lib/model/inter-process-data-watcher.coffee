{File} = require 'pathwatcher'
{Subscriber, Emitter} = require 'emissary'
Q = require 'q'

InterProcessData = require './inter-process-data'

module.exports =
  class InterProcessDataWatcher
    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    data: null

    constructor: (@filePath) ->
      @file = new File(@filePath)
      @subscribe @file, 'contents-changed', => @load()
      @load()

    load: ->
      @file.read().then((content) =>
        @data = InterProcessData.deserialize(JSON.parse(content))
        @subscribe @data, 'contents-changed', => @commit()
        @emit 'contents-changed'
      )

    commit: ->
      @file.write(JSON.stringify(@data.serialize()))
