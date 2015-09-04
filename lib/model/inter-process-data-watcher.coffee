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
      @fsTimeout = undefined

      fs.open(@filePath, 'a', "0644", =>
        @promisedData = @load()
        @watcher()
      )


    watcher: ->
      fs.watch(@filePath, ((event, filename) =>
        if @fsTimeout is undefined and (event is 'change' or event is 'rename')
          @fsTimeout = setTimeout((() => @fsTimeout = undefined; @reloadIfNecessary(); @watcher()), 2000)
        )
      )


    reloadIfNecessary: ->
      if @justCommittedData isnt true
        @data?.destroy()
        @data = undefined
        @promisedData = @load()
      else if @justCommittedData is true
        @justCommittedData = false


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
        interProcessData = undefined
        if data.length > 0
          try
            interProcessData = InterProcessData.deserialize(JSON.parse(data))
          catch e
            console.debug 'Could not parse serialized remote-edit data! Creating an empty InterProcessData object!'
            console.debug e
            interProcessData = new InterProcessData([])
          finally
            @emitter.emit 'did-change'
            deferred.resolve(interProcessData)
        else
          deferred.resolve(new InterProcessData([]))
          @emitter.emit 'did-change'
        )
      )

      deferred.promise


    commit: ->
      @justCommittedData = true
      fs.writeFile(@filePath, JSON.stringify(@data.serialize()), (err) -> throw err if err?)
      @emitter.emit 'did-change'


    onDidChange: (callback) ->
      @emitter.on 'did-change', callback
