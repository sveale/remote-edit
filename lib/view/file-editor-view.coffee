{$, $$$, EditorView, Editor} = require 'atom'
Serializable = require 'serializable'
async = require 'async'
Dialog = require './dialog'

module.exports =
  class FileEditorView extends EditorView
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    constructor: (editor, @uri, @localFile = undefined, @host = undefined) ->
      super(editor)

    getIconName: ->
      "globe"

    getTitle: ->
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
                (callback) =>
                  passwordDialog = new Dialog({prompt: "Enter password"})
                  passwordDialog.attach(callback)
                ], (err, result) =>
                  @upload({password: result})
                )
          )

    getUri: ->
      @uri

    serializeParams: ->
      editor: @editor.serialize()
      uri: @uri
      localFile: @localFile?.serialize()
      host: @host?.serialize()

    deserializeParams: (params) ->
      params.editor = atom.deserializers.deserialize(params.editor)
      params.localFile = atom.deserializers.deserialize(params.localFile)
      params.host = atom.deserializers.deserialize(params.host)
      params
