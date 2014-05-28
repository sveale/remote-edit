{File} = require 'pathwatcher'
{Subscriber, Emitter} = require 'emissary'

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
      @data = InterProcessData.deserialize(JSON.parse(@file.readSync()))
      @data ?= new InterProcessData()
      @emit 'contents-changed'

    commit: ->
      @file.write(JSON.stringify(@data.serialize()))
