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
{Emitter} = require 'emissary'
Path = require 'path'
osenv = require 'osenv'

module.exports =
  class SftpHost extends Host
    Serializable.includeInto(this)
    Host.registerDeserializers(SftpHost)
    Emitter.includeInto(this)


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
        privateKey: @getPrivateKey(@privateKeyPath),
        passphrase: @passphrase
      }

    getConnectionStringUsingPassword: ->
      return {
        host: @hostname,
        port: @port,
        username: @username,
        password: @password
      }

    getPrivateKey: (path) ->
      if path[0] == "~"
        path = Path.normalize(osenv.home() + path.substring(1, path.length))

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
      @emit 'info', {message: "Connecting to #{@username}@#{@hostname}:#{@port}", className: 'text-info'}
      async.waterfall([
        (callback) =>
          @connection = new ssh2()
          @connection.on 'error', (err) =>
            @emit 'info', {message: "Error occured when connecting to #{@username}@#{@hostname}:#{@port}", className: 'text-error'}
            @connection.end()
            callback(err)
          @connection.on 'ready', () =>
            @emit 'info', {message: "Successfully connected to #{@username}@#{@hostname}:#{@port}", className: 'text-success'}
            callback(null)
          @connection.connect(@getConnectionString())
      ], (err) ->
        callback?(err)
      )

    writeFile: (file, text, callback) ->
      @emit 'info', {message: "Writing remote file #{@username}@#{@hostname}:#{@port}#{file.remoteFile.path}", className: 'text-info'}
      async.waterfall([
        (callback) =>
          if !@connection?
            @connect(callback)
          else
            callback(null)
        (callback) =>
          ssh2fs.writeFile(@connection, file.remoteFile.path, text, callback)
        ], (err) =>
          if err?
            @emit('info', {message: "Error occured when writing remote file #{@username}@#{@hostname}:#{@port}#{file.remoteFile.path}", className: 'text-error'})
            console.debug err if err?
          else
            @emit('info', {message: "Successfully wrote remote file #{@username}@#{@hostname}:#{@port}#{file.remoteFile.path}", className: 'text-success'})
          callback?(err)
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
        callback?(err, (result.sort (a, b) => return if a.name.toLowerCase() >= b.name.toLowerCase() then 1 else -1))
      )

    getFileData: (file, callback) ->
      @emit('info', {message: "Getting remote file #{@username}@#{@hostname}:#{@port}#{file.path}", className: 'text-info'})
      ssh2fs.readFile(@connection, file.path, (err, data) =>
        @emit('info', {message: "Error when reading remote file #{@username}@#{@hostname}:#{@port}#{file.path}", className: 'text-error'}) if err?
        @emit('info', {message: "Successfully read remote file #{@username}@#{@hostname}:#{@port}#{file.path}", className: 'text-success'}) if !err?
        callback?(err, data)
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
      tmpArray.push(LocalFile.deserialize(localFile, host: this)) for localFile in JSON.parse(params.localFiles)
      params.localFiles = tmpArray
      params
