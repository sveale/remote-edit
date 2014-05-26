{File} = require 'pathwatcher'
{Subscriber} = require 'emissary'

InterProcessData = require './inter-process-data'

module.exports =
  class InterProcessDataWatcher
    Subscriber.includeInto(this)

    data: null

    constructor: (@filePath) ->
      @file = new File(@filePath)
      @subscribe @file, 'contents-changed', => @load()
      @load()

    load: ->
      console.debug 'load'
      @data = InterProcessData.deserialize(JSON.parse(@file.readSync()))
      @data ?= new InterProcessData()

    commit: ->
      @file.write(JSON.stringify(@data.serialize()))
