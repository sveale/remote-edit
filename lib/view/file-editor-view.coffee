{$$$, EditorView, Editor} = require 'atom'
Serializable = require 'serializable'
util = require 'util'

module.exports =
  class FileEditorView extends EditorView
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    initialize: (editorOrOptions, @uri) ->
      super(editorOrOptions)

    edit: (editor) ->
      super(editor)

    getIconName: ->
      "globe"

    getTitle: ->
      @editor.getTitle()

    save: ->
      @editor.save()

    getUri: ->
      @uri

    serializeParams: ->
      editor: @editor.serialize()
      uri: @uri

    deserializeParams: (params) ->
      params.editor = atom.deserializers.deserialize(params.editor)
      params
