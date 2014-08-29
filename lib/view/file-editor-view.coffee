{$, $$$, EditorView, Editor} = require 'atom'
Serializable = require 'serializable'
async = require 'async'
Dialog = require './dialog'
util = require 'util'

Host = require '../model/host'
FtpHost = require '../model/ftp-host'
SftpHost = require '../model/sftp-host'
LocalFile = require '../model/local-file'

module.exports =
  class FileEditorView extends EditorView
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    localFile: null
    host: null

    constructor: (editor, @uri, @title, @localFile, @host) ->
      super(editor)

    getIconName: ->
      "globe"

    getTitle: ->
      if @title?
        @title
      else
        @editor.getTitle()

    save: ->
      @editor.save()

      if atom.config.get 'remote-edit.uploadOnSave'
        @upload()
      else
        chosen = atom.confirm
          message: "File has been saved. Do you want to upload changes to remote host?"
          detailedMessage: "The changes exists on disk and can be uploaded later."
          buttons: ["Upload", "Cancel"]
        switch chosen
          when 0 then @upload()
          when 1 then return

    upload: (connectionOptions = {}) ->
      if @localFile? and @host?
        async.waterfall([
          (callback) =>
            if !@host.isConnected()
              @host.connect(callback, connectionOptions)
            else
              callback(null)
          (callback) =>
            @host.writeFile(@localFile, @editor.buffer.getText(), callback)
        ], (err) =>
          if err? and @host.usePassword
            async.waterfall([
              (callback) ->
                passwordDialog = new Dialog({prompt: "Enter password"})
                passwordDialog.attach(callback)
            ], (err, result) =>
              @upload({password: result})
            )
        )
      else
        console.error 'LocalFile and host not defined. Cannot upload file!'
        console.debug util.inspect @localFile
        console.debug util.inspect @host

    getUri: ->
      @uri

    serializeParams: ->
      editor: @editor.serialize()
      uri: @uri
      title: @title
      localFile: @localFile?.serialize()
      host: @host?.serialize()

    deserializeParams: (params) ->
      params.editor = atom.deserializers.deserialize(params.editor)
      params.localFile = LocalFile.deserialize(params.localFile)
      params.host = Host.deserialize(params.host)
      params
