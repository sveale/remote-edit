Host = require './host'

RemoteFile = require './remote-file'
LocalFile = require './local-file'

async = require 'async'
filesize = require 'file-size'
moment = require 'moment'
ftp = require 'ftp'
Serializable = require 'serializable'
Path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'

try
  keytar = require 'keytar'
catch err
  console.debug 'Keytar could not be loaded! Passwords will be stored in cleartext to remoteEdit.json!'
  keytar = undefined

module.exports =
  class FtpHost extends Host
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    Host.registerDeserializers(FtpHost)

    connection: undefined
    protocol: "ftp"

    constructor: (@alias = null, @hostname, @directory, @username, @port = "21", @localFiles = [], @usePassword = true,  @password, @lastOpenDirectory) ->
      super( @alias, @hostname, @directory, @username, @port, @localFiles, @usePassword, @lastOpenDirectory )

    createRemoteFileFromListObj: (name, item) ->
      unless item.name? and item.name isnt '..' and item.name isnt '.'
        return undefined

      remoteFile = new RemoteFile(Path.normalize((name + '/' + item.name)).split(Path.sep).join('/'), false, false, false, filesize(item.size).human(), null, null)

      if item.type == "d"
        remoteFile.isDir = true
      else if item.type == "-"
        remoteFile.isFile = true
      else if item.type == 'l'
        remoteFile.isLink = true

      if item.rights?
        remoteFile.permissions = (@convertRWXToNumber(item.rights.user) + @convertRWXToNumber(item.rights.group) + @convertRWXToNumber(item.rights.other))

      if item.date?
        remoteFile.lastModified = moment(item.date).format("HH:mm:ss DD/MM/YYYY")

      return remoteFile

    convertRWXToNumber: (str) ->
      toreturn = 0
      for i in str
        if i == 'r'
          toreturn += 4
        else if i == 'w'
          toreturn += 2
        else if i == 'x'
          toreturn += 1
      return toreturn.toString()

    getServiceNamePassword: ->
      "atom.remote-edit.ftp.password"

    ####################
    # Overridden methods
    getConnectionString: (connectionOptions) ->
      if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (keytar?)
        keytarPassword = keytar.getPassword(@getServiceNamePassword(), @getServiceAccount())
        _.extend({host: @hostname, port: @port, user: @username, password: keytarPassword}, connectionOptions)
      else
        _.extend({host: @hostname, port: @port, user: @username, password: @password}, connectionOptions)


    close: (callback) ->
      @connection?.end()
      callback?(null)

    connect: (callback, connectionOptions = {}) ->
      @emitter.emit 'info', {message: "Connecting to ftp://#{@username}@#{@hostname}:#{@port}", type: 'info'}
      async.waterfall([
        (callback) =>
          @connection = new ftp()
          @connection.on 'error', (err) =>
            @connection.end()
            @emitter.emit 'info', {message: "Error occured when connecting to ftp://#{@username}@#{@hostname}:#{@port}", type: 'error'}
            callback?(err)
          @connection.on 'ready', =>
            @emitter.emit 'info', {message: "Successfully connected to ftp://#{@username}@#{@hostname}:#{@port}", type: 'success'}
            callback(null)
          @connection.connect(@getConnectionString(connectionOptions))
      ], (err) ->
        callback?(err)
      )

    isConnected: ->
      @connection? and @connection.connected

    getFilesMetadata: (path, callback) ->
      async.waterfall([
        (callback) =>
          @connection.list(path, callback)
        (files, callback) =>
          async.map(files, ((item, callback) => callback(null, @createRemoteFileFromListObj(path, item))), callback)
        (objects, callback) ->
          async.filter(objects, ((item, callback) -> callback(item?)), ((result) -> callback(null, result)))
        (objects, callback) ->
          objects.push(new RemoteFile((path + "/.."), false, true, false, null, null, null))
          if atom.config.get 'remote-edit.showHiddenFiles'
            callback(null, objects)
          else
            async.filter(objects, ((item, callback) -> item.isHidden(callback)), ((result) -> callback(null, result)))
      ], (err, result) =>
        if err?
          @emitter.emit('info', {message: "Error occured when reading remote directory ftp://#{@username}@#{@hostname}:#{@port}:#{path}", type: 'error'} )
          console.error err if err?
          callback?(err)
        else
          callback?(err, (result.sort (a, b) -> return if a.name.toLowerCase() >= b.name.toLowerCase() then 1 else -1))
      )

    getFile: (localFile, callback) ->
      @emitter.emit('info', {message: "Getting remote file ftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'info'})
      async.waterfall([
        (callback) =>
          @connection.get(localFile.remoteFile.path, callback)
        (readableStream, callback) =>
          writableStream = fs.createWriteStream(localFile.path)
          readableStream.pipe(writableStream)
          readableStream.on 'end', -> callback(null)
      ], (err) =>
        if err?
          @emitter.emit('info', {message: "Error when reading remote file ftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'error'})
          callback?(err, localFile)
        else
          @emitter.emit('info', {message: "Successfully read remote file ftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'success'})
          callback?(null, localFile)
      )

    writeFile: (localFile, callback) ->
      @emitter.emit 'info', {message: "Writing remote file ftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'info'}
      async.waterfall([
        (callback) =>
          @connection.put(localFile.path, localFile.remoteFile.path, callback)
      ], (err) =>
        if err?
          @emitter.emit('info', {message: "Error occured when writing remote file ftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'error'})
          console.error err if err?
        else
          @emitter.emit('info', {message: "Successfully wrote remote file ftp://#{@username}@#{@hostname}:#{@port}#{localFile.remoteFile.path}", type: 'success'})
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
        @usePassword
        @password
        @lastOpenDirectory
      }

    deserializeParams: (params) ->
      tmpArray = []
      tmpArray.push(LocalFile.deserialize(localFile, host: this)) for localFile in params.localFiles
      params.localFiles = tmpArray
      params
