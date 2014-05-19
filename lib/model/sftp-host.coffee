Host = require './host'

fs = require 'fs'


module.exports =
  class SftpHost extends Host
    constructor: (@hostname, @directory, @username, @port, @useAgent, @usePrivateKey, @usePassword, @password, @passphrase, @privateKeyPath) ->
      super

    getConnectionString: ->
      if @useAgent
        return @getConnectionStringUsingAgent()
      else if @usePrivateKey
        return @getConnectionStringUsingKey()
      else if @usePassword
        return @getConnectionStringUsingPassword()
      else
        throw new Error("No valid connection method is set for SftpHost!")



    getConnectionStringUsingAgent: ->
      return {
        host: @hostname,
        port: @port,
        username: @username,
        agent: process.env['SSH_AUTH_SOCK']
      }

    getConnectionStringUsingKey: ->
      return {
        host: @hostname,
        port: @port,
        username: @username,
        privateKey: @getPrivateKey(@privateKeyPath)
      }


    getConnectionStringUsingPassword: ->
      return {
        host: @hostname,
        port: @port,
        username: @username,
        password: @password
      }

    getPrivateKey = (path) ->
      return fs.readFileSync(path, 'ascii', (err, data) ->
        throw err if err?
        return data.trim()
      )
