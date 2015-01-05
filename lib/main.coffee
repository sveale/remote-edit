# Import needed to register deserializer
RemoteEditEditor = require './model/remote-edit-editor'

# Deferred requirements
OpenFilesView = null
HostView = null
HostsView = null
Host = null
SftpHost = null
FtpHost = null
LocalFile = null
url = null
Q = null
InterProcessDataWatcher = null
fs = null

module.exports =
  config:
    showHiddenFiles:
      title: 'Show hidden files'
      type: 'boolean'
      default: false
    uploadOnSave:
      title: 'Upload on save'
      description: 'When enabled, remote files will be automatically uploaded when saved'
      type: 'boolean'
      default: true
    messagePanel:
      title: 'Display message panel'
      type: 'boolean'
      default: true
    sshPrivateKeyPath:
      title: 'Path to private SSH key'
      type: 'string'
      default: '~/.ssh/id_rsa'
    defaultSerializePath:
      title: 'Default path to serialize remoteEdit data'
      type: 'string'
      default: '~/.atom/remoteEdit.json'
    messagePanelTimeout:
      title: 'Timeout for message panel'
      type: 'integer'
      default: 6000
    agentToUse:
      title: 'SSH agent'
      description: 'Overrides default SSH agent. See ssh2 docs for more info.'
      type: 'string'
      default: 'Default'

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

  initializeIpdwIfNecessary: ->
    if atom.config.get 'remote-edit.messagePanel'
      stop = false
      for editor in atom.workspace.getTextEditors() when !stop
        if editor instanceof RemoteEditEditor
          @createIpdw()
          stop = true

  createIpdw: ->
    unless @ipdw?
      InterProcessDataWatcher ?= require './model/inter-process-data-watcher'
      fs = require 'fs-plus'
      @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
    @ipdw

  setupOpeners: ->
    atom.workspace.addOpener (uriToOpen) ->
      url ?= require 'url'
      try
        {protocol, host, query} = url.parse(uriToOpen, true)
      catch error
        return
      return unless protocol is 'remote-edit:'

      if host is 'localfile'
        Q ?= require 'q'
        Host ?= require './model/host'
        FtpHost ?= require './model/ftp-host'
        SftpHost ?= require './model/sftp-host'
        LocalFile ?= require './model/local-file'
        localFile = LocalFile.deserialize(JSON.parse(decodeURIComponent(query.localFile)))
        host = Host.deserialize(JSON.parse(decodeURIComponent(query.host)))

        atom.project.bufferForPath(localFile.path).then (buffer) ->
          editor = new RemoteEditEditor({buffer: buffer, registerEditor: true, host: host, localFile: localFile})
