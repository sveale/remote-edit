path = require 'path'
resourcePath = atom.config.resourcePath
try
  Editor = require path.resolve resourcePath, 'src', 'editor'
catch e
  # Catch error
TextEditor = Editor ? require path.resolve resourcePath, 'src', 'text-editor'

DisplayBuffer = require path.resolve resourcePath, 'src', 'display-buffer'

# Defer requiring
Host = null
FtpHost = null
SftpHost = null
LocalFile = null
async = null
Dialog = null
_ = null

module.exports =
  class RemoteEditEditor extends TextEditor
    atom.deserializers.add(this)

    constructor: ({@softTabs, initialLine, initialColumn, tabLength, softWrap, @displayBuffer, buffer, registerEditor, suppressCursorCreation, @mini, @host, @localFile}) ->
      super({@softTabs, initialLine, initialColumn, tabLength, softWrap, @displayBuffer, buffer, registerEditor, suppressCursorCreation, @mini})

    getIconName: ->
      "globe"

    getTitle: ->
      if @localFile?
        @localFile.name
      else if sessionPath = @getPath()
        path.basename(sessionPath)
      else
        "undefined"

    getLongTitle: ->
      Host ?= require './host'
      FtpHost ?= require './ftp-host'
      SftpHost ?= require './sftp-host'

      if i = @localFile.remoteFile.path.indexOf(@host.directory) > -1
        relativePath = @localFile.remoteFile.path[(i+@host.directory.length)..]

      fileName = @getTitle()
      if @host instanceof SftpHost and @host? and @localFile?
        directory = if relativePath? then relativePath else "sftp://#{@host.username}@#{@host.hostname}:#{@host.port}#{@localFile.remoteFile.path}"
      else if @host instanceof FtpHost and @host? and @localFile?
        directory = if relativePath? then relativePath else "ftp://#{@host.username}@#{@host.hostname}:#{@host.port}#{@localFile.remoteFile.path}"
      else
        directory = atom.project.relativize(path.dirname(sessionPath))
        directory = if directory.length > 0 then directory else path.basename(path.dirname(sessionPath))

      "#{fileName} - #{directory}"

    onDidSaved: (callback) ->
      @emitter.on 'did-saved', callback

    save: ->
      @buffer.save()
      @emitter.emit 'saved'
      @initiateUpload()

    saveAs: (filePath) ->
      @buffer.saveAs(filePath)
      @localFile.path = filePath
      @emitter.emit 'saved'
      @initiateUpload()

    initiateUpload: ->
      if atom.config.get 'remote-edit.uploadOnSave'
        @upload()
      else
        Dialog ?= require '../view/dialog'
        chosen = atom.confirm
          message: "File has been saved. Do you want to upload changes to remote host?"
          detailedMessage: "The changes exists on disk and can be uploaded later."
          buttons: ["Upload", "Cancel"]
        switch chosen
          when 0 then @upload()
          when 1 then return

    upload: (connectionOptions = {}) ->
      async ?= require 'async'
      _ ?= require 'underscore-plus'
      if @localFile? and @host?
        async.waterfall([
          (callback) =>
            if @host.usePassword and !connectionOptions.password?
              if @host.password == "" or @host.password == '' or !@host.password?
                async.waterfall([
                  (callback) ->
                    Dialog ?= require '../view/dialog'
                    passwordDialog = new Dialog({prompt: "Enter password"})
                    passwordDialog.toggle(callback)
                ], (err, result) =>
                  connectionOptions = _.extend({password: result}, connectionOptions)
                  callback(null)
                )
              else
                callback(null)
            else
              callback(null)
          (callback) =>
            if !@host.isConnected()
              @host.connect(callback, connectionOptions)
            else
              callback(null)
          (callback) =>
            @host.writeFile(@localFile, callback)
        ], (err) =>
          if err? and @host.usePassword
            async.waterfall([
              (callback) ->
                Dialog ?= require '../view/dialog'
                passwordDialog = new Dialog({prompt: "Enter password"})
                passwordDialog.toggle(callback)
            ], (err, result) =>
              @upload({password: result})
            )
        )
      else
        console.error 'LocalFile and host not defined. Cannot upload file!'

    serialize: ->
      deserializer: 'RemoteEditEditor'
      id: @id
      softTabs: @softTabs
      scrollTop: @scrollTop
      scrollLeft: @scrollLeft
      displayBuffer: @displayBuffer.serialize()
      title: @title
      localFile: @localFile?.serialize()
      host: @host?.serialize()

    @deserialize: (state) ->
      try
        displayBuffer = DisplayBuffer.deserialize(state.displayBuffer)
      catch error
        if error.syscall is 'read'
          return # error reading the file, dont deserialize an editor for it
        else
          throw error
      state.displayBuffer = displayBuffer
      state.registerEditor = true
      if state.localFile?
        LocalFile = require '../model/local-file'
        state.localFile = LocalFile.deserialize(state.localFile)
      if state.host?
        Host = require '../model/host'
        FtpHost = require '../model/ftp-host'
        SftpHost = require '../model/sftp-host'
        state.host = Host.deserialize(state.host)
      new this(state)
