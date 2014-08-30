# Import needed to register deserializers
FileEditorView = require './view/file-editor-view'

module.exports =
  configDefaults:
    showHiddenFiles: false,
    uploadOnSave: true,
    messagePanel: true,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    defaultSerializePath: "~/.atom/remoteEdit.json",
    messagePanelTimeout: 6000

  activate: (state) ->
    @createIpdw()
    @setupOpeners()

    atom.workspaceView.command "remote-edit:show-open-files", =>
      OpenFilesView = require './view/open-files-view'
      showOpenFilesView = new OpenFilesView(@createIpdw())
      showOpenFilesView.attach()

    atom.workspaceView.command "remote-edit:browse", =>
      HostsView = require './view/hosts-view'
      view = new HostsView(@createIpdw())
      view.attach()

    atom.workspaceView.command "remote-edit:new-host-sftp", =>
      HostView = require './view/host-view'
      SftpHost = require './model/sftp-host'
      host = new SftpHost()
      view = new HostView(host, @createIpdw())
      view.attach()

    atom.workspaceView.command "remote-edit:new-host-ftp", =>
      HostView = require './view/host-view'
      FtpHost = require './model/ftp-host'
      host = new FtpHost()
      view = new HostView(host, @createIpdw())
      view.attach()

  deactivate: ->
    @view?.destroy()

  setupOpeners: ->
    @openers = true
    atom.workspace.registerOpener (uriToOpen) ->
      url = require 'url'
      try
        {protocol, host, query} = url.parse(uriToOpen, true)
      catch error
        return
      return unless protocol is 'remote-edit:'

      if host is 'localfile'
        Q = require 'q'
        atom.project.open(query.path).then (editor) -> new FileEditorView(editor, uriToOpen, query.title)

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
      else
        return

  createIpdw: ->
    unless @ipdw?
      InterProcessDataWatcher = require './model/inter-process-data-watcher'
      fs = require 'fs-plus'
      @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
    @ipdw
