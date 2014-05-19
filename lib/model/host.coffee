module.exports =
  class Host
    constructor: (@hostname, @directory, @username, @port) ->

    getConnectionString: ->
      throw new Error("Function getConnectionString() needs to be implemented by subclasses!")
