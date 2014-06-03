MainView = require './main-view'
util = require 'util'
_ = require 'underscore-plus'
FileEditorView = require './view/file-editor-view'
url = require 'url'
Q = require 'q'

module.exports =
  configDefaults:
    showHiddenFiles: false,
    numberOfConcurrentSshQueriesInOneConnection: 5,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    defaultSerializePath: "~/.atom/remoteEdit.json"

  activate: (state) ->
    @setupOpener()
    @view = new MainView()

  deactivate: ->
    @view?.destroy()

  serialize: ->
    @view?.serialize()

  setupOpener: ->
    atom.workspace.registerOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return
      return unless protocol is 'remote-edit:'

      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return

      if host is 'editor'
        atom.project.open(pathname).then (editor) -> new FileEditorView(editor, uriToOpen)
      else
        undefined
