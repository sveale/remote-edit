# Import needed to register deserializers
FileEditorView = require './view/file-editor-view'

# Deferred requirements
OpenFilesView = null
HostView = null
HostsView = null
SftpHost = null
FtpHost = null
url = null
Q = null
InterProcessDataWatcher = null
fs = null

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
    @initializeIpdwIfNecessary()

    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles()
    atom.workspaceView.command "remote-edit:browse", => @browse()
    atom.workspaceView.command "remote-edit:new-host-sftp", => @newHostSftp()
    atom.workspaceView.command "remote-edit:new-host-ftp", => @newHostFtp()

  deactivate: ->
    @view?.destroy()

  newHostSftp: ->
    HostView ?= require './view/host-view'
    SftpHost ?= require './model/sftp-host'
    host = new SftpHost()
    view = new HostView(host, @createIpdw())
    view.attach()

  newHostFtp: ->
    HostView ?= require './view/host-view'
    FtpHost ?= require './model/ftp-host'
    host = new FtpHost()
    view = new HostView(host, @createIpdw())
    view.attach()

  browse: ->
    HostsView ?= require './view/hosts-view'
    view = new HostsView(@createIpdw())
    view.attach()

  showOpenFiles: ->
    OpenFilesView ?= require './view/open-files-view'
    showOpenFilesView = new OpenFilesView(@createIpdw())
    showOpenFilesView.attach()

  setupOpeners: ->
    atom.workspace.registerOpener (uriToOpen) ->
      url ?= require 'url'
      try
        {protocol, host, query} = url.parse(uriToOpen, true)
      catch error
        return
      return unless protocol is 'remote-edit:'

      if host is 'localfile'
        Q ?= require 'q'
        atom.project.open(query.path).then (editor) -> new FileEditorView(editor, uriToOpen, query.title)

  initializeIpdwIfNecessary: ->
    if atom.config.get 'remote-edit.messagePanel'
      stop = false
      for pane in atom.workspaceView.getPaneViews() when !stop
        for item in pane.getItems() when !stop
          if item instanceof FileEditorView
            @createIpdw()
            stop = true

  createIpdw: ->
    unless @ipdw?
      InterProcessDataWatcher ?= require './model/inter-process-data-watcher'
      fs = require 'fs-plus'
      @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
    @ipdw
