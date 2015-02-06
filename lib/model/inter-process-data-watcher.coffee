{CompositeDisposable, Emitter} = require 'atom'
Q = require 'q'
fs = require 'fs-plus'

# Defer requiring
InterProcessData = null


module.exports =
  class InterProcessDataWatcher
    constructor: (@filePath) ->
      @emitter = new Emitter
      @disposables = new CompositeDisposable
      @data = Q.defer().promise

      fs.open(@filePath, 'a', "0644", =>
        @data = @load()
        fs.watch(@filePath, ((event, filename) =>
          if event == 'change'
            @data.then (resolvedData) =>
              resolvedData.reset()
              @data = @load()
          )
        )
      )

    load: ->
      deferred = Q.defer()

      fs.readFile(@filePath, 'utf8', ((err, data) ->
        InterProcessData ?= require './inter-process-data'
        throw err if err?
        if data.length > 0
          deferred.resolve(InterProcessData.deserialize(JSON.parse(data)))
        else
          deferred.resolve(new InterProcessData([]))
        )
      )

      deferred.promise.then (data) =>
        @disposables.add data.onDidChange => @commit()
        @emitter.emit 'did-change'

      deferred.promise


    commit: ->
      @data.then (resolvedData) =>
        fs.writeFile(@filePath, JSON.stringify(resolvedData.serialize()), ((err) -> throw err if err?))

    onDidChange: (callback) ->
      @emitter.on 'did-change', callback
