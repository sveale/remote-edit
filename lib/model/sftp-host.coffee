Host = require './host'
RemoteFile = require './remote-file'
LocalFile = require './local-file'

fs = require 'fs-plus'
ssh2 = require 'ssh2'
async = require 'async'
util = require 'util'
filesize = require 'file-size'
moment = require 'moment'
Serializable = require 'serializable'
Path = require 'path'
osenv = require 'osenv'
_ = require 'underscore-plus'
try
  keytar = require 'keytar'
catch err
  console.debug 'Keytar could not be loaded! Passwords will be stored in cleartext to remoteEdit.json!'
  keytar = undefined

module.exports =
  class SftpHost extends Host
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    Host.registerDeserializers(SftpHost)

    connection: undefined
    protocol: "sftp"

    constructor: (@alias = null, @hostname, @directory, @username, @port = "22", @localFiles = [], @usePassword = false, @useAgent = true, @usePrivateKey = false, @password, @passphrase, @privateKeyPath, @lastOpenDirectory) ->
      super( @alias, @hostname, @directory, @username, @port, @localFiles, @usePassword, @lastOpenDirectory)

    getConnectionStringUsingAgent: ->
      connectionString =  {
        host: @hostname,
        port: @port,
        username: @username,
      }

      if atom.config.get('remote-edit.agentToUse') != 'Default'
        _.extend(connectionString, {agent: atom.config.get('remote-edit.agentToUse')})
      else if process.platform == "win32"
        _.extend(connectionString, {agent: 'pageant'})
      else
        _.extend(connectionString, {agent: process.env['SSH_AUTH_SOCK']})

      connectionString

    getConnectionStringUsingKey: ->
      if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (keytar?)
        keytarPassphrase = keytar.getPassword(@getServiceNamePassphrase(), @getServiceAccount())
        {host: @hostname, port: @port, username: @username, privateKey: @getPrivateKey(@privateKeyPath), passphrase: keytarPassphrase}
      else
        {host: @hostname, port: @port, username: @username, privateKey: @getPrivateKey(@privateKeyPath), passphrase: @passphrase}


    getConnectionStringUsingPassword: ->
      if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (keytar?)
        keytarPassword = keytar.getPassword(@getServiceNamePassword(), @getServiceAccount())
        {host: @hostname, port: @port, username: @username, password: keytarPassword}
      else
        {host: @hostname, port: @port, username: @username, password: @password}

    getPrivateKey: (path) ->
      if path[0] == "~"
        path = Path.normalize(osenv.home() + path.substring(1, path.length))

      return fs.readFileSync(path, 'ascii', (err, data) ->
        throw err if err?
        return data.trim()
      )

    createRemoteFileFromFile: (path, file) ->
      remoteFile = new RemoteFile(Path.normalize("#{path}/#{file.filename}").split(Path.sep).join('/'), (file.longname[0] == '-'), (file.longname[0] == 'd'), (file.longname[0] == 'l'), filesize(file.attrs.size).human(), parseInt(file.attrs.mode, 10).toString(8).substr(2, 4), moment(file.attrs.mtime * 1000).format("HH:mm:ss DD/MM/YYYY"))
      return remoteFile

    getServiceNamePassword: ->
      "atom.remote-edit.ssh.password"

    getServiceNamePassphrase: ->
      "atom.remote-edit.ssh.passphrase"

    ####################
    # Overridden methods
    getConnectionString: (connectionOptions) ->
      if @useAgent
        return _.extend(@getConnectionStringUsingAgent(), connectionOptions)
      else if @usePrivateKey
        return _.extend(@getConnectionStringUsingKey(), connectionOptions)
      else if @usePassword
        return _.extend(@getConnectionStringUsingPassword(), connectionOptions)
      else
        throw new Error("No valid connection method is set for SftpHost!")

    close: (callback) ->
      @connection?.end()
      callback?(null)

    connect: (callback, connectionOptions = {}) ->
      @emitter.emit 'info', {message: "Connecting to sftp://#{@username}@#{@hostname}:#{@port}", type: 'info'}
      async.waterfall([
        (callback) =>
          if @usePrivateKey
            fs.exists(@privateKeyPath, ((exists) =>
              if exists
                callback(null)
              else
                @emitter.emit 'info', {message: "Private key does not exist!", type: 'error'}
                callback(new Error("Private key does not exist"))
              )
            )
          else
            callback(null)
        (callback) =>
          @connection = new ssh2()
          @connection.on 'error', (err) =>
            @emitter.emit 'info', {message: "Error occured when connecting to sftp://#{@username}@#{@hostname}:#{@port}", type: 'error'}
            @connection.end()
            callback(err)
          @connection.on 'ready', =>
            @emitter.emit 'info', {message: "Successfully connected to sftp://#{@username}@#{@hostname}:#{@port}", type: 'success'}
            callback(null)
          @connection.connect(@getConnectionString(connectionOptions))
      ], (err) ->
        callback?(err)
      )

    isConnected: ->
      @connection? and @connection._state == 'authenticated'

    getFilesMetadata: (path, callback) ->
      async.waterfall([
        (callback) =>
          @connection.sftp(callback)
        (sftp, callback) ->
          sftp.readdir(path, callback)
        (files, callback) =>
          async.map(files, ((file, callback) => callback(null, @createRemoteFileFromFile(path, file))), callback)
        (objects, callback) ->
          objects.push(new RemoteFile((path + "/.."), false, true, false, null, null, null))
          if atom.config.get 'remote-edit.showHiddenFiles'
            callback(null, objects)
          else
            async.filter(objects, ((item, callback) -> item.isHidden(callback)), ((result) -> callback(null, result)))
      ], (err, result) =>
        if err?
          @emitter.emit('info', {message: "Error occured when reading remote directory sftp://#{@username}@#{@hostname}:#{@port}:#{path}", type: 'error'} )
          console.error err if err?
          callback?(err)
        else
          callback?(err, (result.sort (a, b) -> return if a.name.toLowerCase() >= b.name.toLowerCase() then 1 else -1))
      )

    getFile: (localFile, callback) ->
      @emitter.emit('info', {message: "Getting remote file sftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'info'})
      async.waterfall([
        (callback) =>
          @connection.sftp(callback)
        (sftp, callback) =>
          sftp.fastGet(localFile.remoteFile.path, localFile.path, (err) => callback(err, sftp))
      ], (err, sftp) =>
        @emitter.emit('info', {message: "Error when reading remote file sftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'error'}) if err?
        @emitter.emit('info', {message: "Successfully read remote file sftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'success'}) if !err?
        callback?(err, localFile)
      )

    writeFile: (localFile, callback) ->
      @emitter.emit 'info', {message: "Writing remote file sftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'info'}
      async.waterfall([
        (callback) =>
          @connection.sftp(callback)
        (sftp, callback) ->
          sftp.fastPut(localFile.path, localFile.remoteFile.path, callback)
      ], (err) =>
        if err?
          @emitter.emit('info', {message: "Error occured when writing remote file sftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'error'})
          console.error err if err?
        else
          @emitter.emit('info', {message: "Successfully wrote remote file sftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'success'})
        @close()
        callback?(err)
      )

    serializeParams: ->
      {
        @alias
        @hostname
        @directory
        @username
        @port
        localFiles: localFile.serialize() for localFile in @localFiles
        @useAgent
        @usePrivateKey
        @usePassword
        @password
        @passphrase
        @privateKeyPath
        @lastOpenDirectory
      }

    deserializeParams: (params) ->
      tmpArray = []
      tmpArray.push(LocalFile.deserialize(localFile, host: this)) for localFile in params.localFiles
      params.localFiles = tmpArray
      params
