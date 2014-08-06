module.exports =
  configDefaults:
    showHiddenFiles: false,
    numberOfConcurrentSshQueriesInOneConnection: 5,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    defaultSerializePath: "~/.atom/remoteEdit.json",
    uploadOnSave: true

  getView: ->
    MainView = require './main-view'
    @view ?= new MainView()

  activate: (state) ->
    @setupOpeners()

    atom.workspaceView.command "remote-edit:show-open-files", =>
      @getView().showOpenFiles()

    atom.workspaceView.command "remote-edit:browse", =>
      @getView().browse()

    atom.workspaceView.command "remote-edit:new-host-sftp", =>
      @getView().newHost("sftp")

    atom.workspaceView.command "remote-edit:new-host-ftp", =>
      @getView().newHost("ftp")

  deactivate: ->
    @view?.destroy()

  setupOpeners: ->
    atom.workspace.registerOpener (uriToOpen) ->
      url = require 'url'
      try
        {protocol, host, query} = url.parse(uriToOpen, true)
      catch error
        return
      return unless protocol is 'remote-edit:'

      console.debug 'wtf'

      if host is 'localfile'
        Q = require 'q'
        FileEditorView = require './view/file-editor-view'
        atom.project.open(query.path).then (editor) -> new FileEditorView(editor, uriToOpen)
      else
        return

    atom.workspace.registerOpener (uriToOpen) ->
      url = require 'url'
      try
        parsedUri = url.parse(uriToOpen, true)
      catch error
        return

      if parsedUri.protocol is 'sftp:'
        SftpHost = require './model/sftp-host'
        host = new SftpHost(parsedUri.hostname, (parsedUri.pathname ? '/'), (parsedUri.auth.split(':')[0] ? parsedUri.auth), (parsedUri.port ? 22), [], true, false, false, (parsedUri.auth.split(':')[1] ? ""), null, null)
      else if parsedUri.protocol is 'ftp:'
        FtpHost = require './model/ftp-host'
        host = new FtpHost(parsedUri.hostname, (parsedUri.pathname ? '/'), (parsedUri.auth.split(':')[0] ? parsedUri.auth), (parsedUri.port ? 21), null, true, (parsedUri.auth.split(':')[1] ? null))

      if host?
        FilesView = require './view/files-view'
        filesView = new FilesView(host)
        filesView.attach()

      throw Error("No promises :)")
      return
