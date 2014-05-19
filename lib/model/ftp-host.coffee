Host = require './host'

module.exports =
  class FtpHost extends Host
    constructor: (@hostname, @directory, @username, @port) ->
      super
