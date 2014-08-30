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
    @setupOpeners()
    if atom.config.get 'remote-edit.messagePanel'
      stop = false
      for pane in atom.workspaceView.getPaneViews() when !stop
        for item in pane.getItems() when !stop
          if item instanceof FileEditorView
            @createIpdw()
            stop = true

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

  createIpdw: ->
    unless @ipdw?
      InterProcessDataWatcher = require './model/inter-process-data-watcher'
      fs = require 'fs-plus'
      @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
    @ipdw
