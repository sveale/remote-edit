{Subscriber, Emitter} = require 'emissary'
Q = require 'q'
util = require 'util'
fs = require 'fs-plus'

InterProcessData = require './inter-process-data'


module.exports =
  class InterProcessDataWatcher
    Subscriber.includeInto(this)
    Emitter.includeInto(this)

    constructor: (@filePath) ->
      @data = Q.defer().promise

      fs.open(@filePath, 'a', "0644", =>
        @data = @load()
        fs.watch(@filePath, ((event, filename) =>
          if event == 'change'
            @data = @load()
          )
        )
      )

    load: ->
      deferred = Q.defer()

      fs.readFile(@filePath, 'utf8', ((err, data) ->
        throw err if err?
        if data.length > 0
          deferred.resolve(InterProcessData.deserialize(JSON.parse(data)))
        else
          deferred.resolve(new InterProcessData([]))
        )
      )

      deferred.promise.then (data) =>
        @subscribe data, 'contents-changed', => @commit()
        @emit 'contents-changed'

      deferred.promise


    commit: ->
      @data.then (resolvedData) =>
        fs.writeFile(@filePath, JSON.stringify(resolvedData.serialize()), ((err) ->
          throw err if err?
          )
        )
