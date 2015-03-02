{CompositeDisposable, Emitter} = require 'atom'
Q = require 'q'
fs = require 'fs-plus'

# Defer requiring
InterProcessData = null


module.exports =
  class InterProcessDataWatcher
    constructor: (@filePath) ->
      @justCommittedData = false
      @emitter = new Emitter
      @disposables = new CompositeDisposable
      @promisedData = Q.defer().promise

      fs.open(@filePath, 'a', "0644", =>
        @promisedData = @load()

        fs.watch(@filePath, ((event, filename) =>
          if event is 'change' and @justCommittedData is false
            @data?.destroy()
            @data = undefined
            @promisedData = @load()
          else if event is 'change' and @justCommittedData is true
            @justCommittedData = false
          )
        )
      )

    # Should return InterProcessData object
    getData: ->
      deferred = Q.defer()

      if @data is undefined
        @promisedData.then (resolvedData) =>
          @data = resolvedData
          @disposables.add @data.onDidChange => @commit()
          deferred.resolve(@data)
      else
        deferred.resolve(@data)

      deferred.promise


    destroy: ->
      @disposables.dispose()
      @emitter.dispose()
      @data?.destroy()

    load: ->
      deferred = Q.defer()

      fs.readFile(@filePath, 'utf8', ((err, data) =>
        InterProcessData ?= require './inter-process-data'
        throw err if err?
        if data.length > 0
          data = InterProcessData.deserialize(JSON.parse(data))
          @emitter.emit 'did-change'
          deferred.resolve(data)
        else
          data = new InterProcessData([])
          @emitter.emit 'did-change'
          deferred.resolve(data)
        )
      )

      deferred.promise


    commit: ->
      @justCommittedData = true
      fs.writeFile(@filePath, JSON.stringify(@data.serialize()), (err) -> throw err if err?)
      @emitter.emit 'did-change'

    onDidChange: (callback) ->
      @emitter.on 'did-change', callback
