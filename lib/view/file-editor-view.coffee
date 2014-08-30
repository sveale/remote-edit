{EditorView, Editor} = require 'atom'
Serializable = require 'serializable'

# Defer requiring
Host = null
FtpHost = null
SftpHost = null
LocalFile = null
async = null
Dialog = null
_ = null

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
        Dialog
        chosen = atom.confirm
          message: "File has been saved. Do you want to upload changes to remote host?"
          detailedMessage: "The changes exists on disk and can be uploaded later."
          buttons: ["Upload", "Cancel"]
        switch chosen
          when 0 then @upload()
          when 1 then return

    upload: (connectionOptions = {}) ->
      Dialog ?= require './Dialog'
      async ?= require 'async'
      _ ?= require 'underscore-plus'
      if @localFile? and @host?
        async.waterfall([
          (callback) =>
            if @host.usePassword and !connectionOptions.password?
              if @host.password == "" or @host.password == '' or !@host.password?
                async.waterfall([
                  (callback) ->
                    passwordDialog = new Dialog({prompt: "Enter password"})
                    passwordDialog.attach(callback)
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
      if params.localFile?
        LocalFile = require '../model/local-file'
        params.localFile = LocalFile.deserialize(params.localFile)
      if params.host?
        Host = require '../model/host'
        FtpHost = require '../model/ftp-host'
        SftpHost = require '../model/sftp-host'
        params.host = Host.deserialize(params.host)
      params
