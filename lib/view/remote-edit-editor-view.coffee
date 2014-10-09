{$, $$$} = require 'atom'
path = require 'path'
resourcePath = atom.config.resourcePath
try
  EditorView = require path.resolve resourcePath, 'src', 'editor-view'
catch e
  # Catch error
TextEditorView = EditorView ? require path.resolve resourcePath, 'src', 'text-editor-view'

RemoteEditEditor = require '../model/remote-edit-editor'

# Defer requiring
Host = null
FtpHost = null
SftpHost = null
LocalFile = null
async = null
Dialog = null
_ = null

module.exports =
  class RemoteEditEditorView extends TextEditorView
    constructor: (editor) ->
      if editor not instanceof RemoteEditEditor
        throw new Error("Can only handle RemoteEditEditor!")

      @addClass("remote-edit-file-editor")


      super(editor)

      @subscribe editor, 'saved', =>
        @save()

    getIconName: ->
      "globe"

    getTitle: ->
      @editor?.getTitle() ? "undefined"

    save: ->
      if atom.config.get 'remote-edit.uploadOnSave'
        @upload()
      else
        Dialog ?= require './dialog'
        chosen = atom.confirm
          message: "File has been saved. Do you want to upload changes to remote host?"
          detailedMessage: "The changes exists on disk and can be uploaded later."
          buttons: ["Upload", "Cancel"]
        switch chosen
          when 0 then @upload()
          when 1 then return

    upload: (connectionOptions = {}) ->
      Dialog ?= require './dialog'
      async ?= require 'async'
      _ ?= require 'underscore-plus'
      if @editor.localFile? and @editor.host?
        async.waterfall([
          (callback) =>
            if @editor.host.usePassword and !connectionOptions.password?
              if @editor.host.password == "" or @editor.host.password == '' or !@editor.host.password?
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
            if !@editor.host.isConnected()
              @editor.host.connect(callback, connectionOptions)
            else
              callback(null)
          (callback) =>
            @editor.host.writeFile(@editor.localFile, @editor.buffer.getText(), callback)
        ], (err) =>
          if err? and @editor.host.usePassword
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
      return @editor?.getUri()
