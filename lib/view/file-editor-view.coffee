{$$$, EditorView, Editor} = require 'atom'
Serializable = require 'serializable'
util = require 'util'

LocalFile = require '../model/local-file'
Host = require '../model/host'

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
      if @localFile? and @host?
        @host.writeFile(@localFile, @editor.buffer.getText(), null)
      @editor.save()

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
