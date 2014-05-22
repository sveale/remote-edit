Host = require './host'
RemoteFile = require './remote-file'
LocalFile = require './local-file'

fs = require 'fs'
ssh2fs = require 'ssh2-fs'
ssh2 = require 'ssh2'
async = require 'async'
util = require 'util'
filesize = require 'file-size'
moment = require 'moment'
Serializable = require 'serializable'

module.exports =
  class SftpHost extends Host
    Serializable.includeInto(this)
    Host.registerDeserializers(SftpHost)


    constructor: (@hostname, @directory, @username, @port, @localFiles = [], @useAgent, @usePrivateKey, @usePassword, @password, @passphrase, @privateKeyPath) ->
      super

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

    createRemoteFileFromNameAndStat: (name, stat) ->
      remoteFile = new RemoteFile(name, stat.isFile(),
                                  stat.isDirectory(),
                                  filesize(stat.size).human(),
                                  parseInt(stat.permissions, 10).toString(8).substr(2, 4),
                                  moment(stat.mtime * 1000).format("HH:MM DD/MM/YYYY"))
      return remoteFile

    getNumberOfConcurrentSshQueriesInOneConnection: ->
      atom.config.get 'remote-edit.numberOfConcurrentSshConnectionToOneHost'

    ####################
    # Overridden methods
    getConnectionString: ->
      if @useAgent
        return @getConnectionStringUsingAgent()
      else if @usePrivateKey
        return @getConnectionStringUsingKey()
      else if @usePassword
        return @getConnectionStringUsingPassword()
      else
        throw new Error("No valid connection method is set for SftpHost!")

    connect: (callback) ->
      async.waterfall([
        (callback) =>
          @connection = new ssh2()
          @connection.on 'error', (err) =>
            @connection.end()
            callback(err)
          @connection.on 'ready', () ->
            callback(null)
          @connection.connect(@getConnectionString())
      ], (err, result) ->

        callback(err, result)
      )

    getFilesMetadata: (path, callback) ->
      async.waterfall([
        (callback) =>
          ssh2fs.readdir(@connection, path, callback)
        (files, callback) =>
          async.mapLimit(files, @getNumberOfConcurrentSshQueriesInOneConnection(), ((item, callback) => ssh2fs.stat(@connection, (path + "/" + item), (err, stat) => callback(err, @createRemoteFileFromNameAndStat((path + "/" + item), stat)))), callback)
        (objects, callback) =>
          if atom.config.get 'remote-edit.showHiddenFiles'
            callback(null, objects)
          else
            async.filter(objects, ((item, callback) -> item.isHidden(callback)), ((result) => callback(null, result)))
      ], (err, result) =>
        return callback(err, (result.sort (a, b) => return if a.name.toLowerCase() >= b.name.toLowerCase() then 1 else -1))
      )

    getFileData: (file, callback) ->
      ssh2fs.readFile(@connection, file.path, (err, data) ->
        return callback(err, data)
      )

    serializeParams: ->
      {
        @hostname
        @directory
        @username
        @port
        localFiles: JSON.stringify(localFile.serialize() for localFile in @localFiles)
        @useAgent
        @usePrivateKey
        @usePassword
        @password
        @passphrase
        @privateKeyPath
      }

    deserializeParams: (params) ->
      tmpArray = []
      tmpArray.push(LocalFile.deserialize(localFile)) for localFile in JSON.parse(params.localFiles)
      params.localFiles = tmpArray
      params
