_ = require 'underscore-plus'
# Import needed to register deserializer
RemoteEditEditor = require './model/remote-edit-editor'

# Deferred requirements
OpenFilesView = null
HostView = null
HostsView = null
FilesView = null
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
    notifications:
      title: 'Display notifications'
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
    agentToUse:
      title: 'SSH agent'
      description: 'Overrides default SSH agent. See ssh2 docs for more info.'
      type: 'string'
      default: 'Default'
    foldersOnTop:
      title: 'Show folders on top'
      type: 'boolean'
      default: false
    followLinks:
      title: 'Follow symbolic links'
      description: 'If set to true, symbolic links are treated as directories'
      type: 'boolean'
      default: true
    clearFileList:
      title: 'Clear file list'
      description: 'When enabled, the open files list will be cleared on initialization'
      type: 'boolean'
      default: false
    rememberLastOpenDirectory:
      title: 'Remember last open directory'
      description: 'When enabled, browsing a host will return you to the last directory you entered'
      type: 'boolean'
      default: false
    storePasswordsUsingKeytar:
      title: 'Store passwords using node-keytar'
      description: 'When enabled, passwords and passphrases will be stored in system\'s keychain'
      type: 'boolean'
      default: false
    filterHostsUsing:
      type: 'object'
      properties:
        hostname:
          type: 'boolean'
          default: true
        alias:
          type: 'boolean'
          default: false
        username:
          type: 'boolean'
          default: false
        port:
          type: 'boolean'
          default: false


  activate: (state) ->
    @setupOpeners()
    @initializeIpdwIfNecessary()

    atom.commands.add('atom-workspace', 'remote-edit:show-open-files', => @showOpenFiles())
    atom.commands.add('atom-workspace', 'remote-edit:browse', => @browse())
    atom.commands.add('atom-workspace', 'remote-edit:new-host-sftp', => @newHostSftp())
    atom.commands.add('atom-workspace', 'remote-edit:new-host-ftp', => @newHostFtp())
    atom.commands.add('atom-workspace', 'remote-edit:toggle-files-view', => @createFilesView().toggle())
    atom.commands.add('atom-workspace', 'remote-edit:reload-folder', => @createFilesView().reloadFolder())
    atom.commands.add('atom-workspace', 'remote-edit:create-folder', => @createFilesView().createFolder())
    atom.commands.add('atom-workspace', 'remote-edit:create-file', => @createFilesView().createFile())
    atom.commands.add('atom-workspace', 'remote-edit:rename-folder-file', => @createFilesView().renameFolderFile())
    atom.commands.add('atom-workspace', 'remote-edit:remove-folder-file', => @createFilesView().deleteFolderFile())

  deactivate: ->
    @ipdw?.destroy()

  newHostSftp: ->
    HostView ?= require './view/host-view'
    SftpHost ?= require './model/sftp-host'
    host = new SftpHost()
    view = new HostView(host, @getOrCreateIpdw())
    view.toggle()

  newHostFtp: ->
    HostView ?= require './view/host-view'
    FtpHost ?= require './model/ftp-host'
    host = new FtpHost()
    view = new HostView(host, @getOrCreateIpdw())
    view.toggle()

  browse: ->
    HostsView ?= require './view/hosts-view'
    view = new HostsView(@getOrCreateIpdw())
    view.toggle()

  showOpenFiles: ->
    OpenFilesView ?= require './view/open-files-view'
    showOpenFilesView = new OpenFilesView(@getOrCreateIpdw())
    showOpenFilesView.toggle()

  createFilesView: ->
    unless @filesView?
      FilesView = require './view/files-view'
      @filesView = new FilesView(@state)
    @filesView

  initializeIpdwIfNecessary: ->
    if atom.config.get 'remote-edit.notifications'
      stop = false
      for editor in atom.workspace.getTextEditors() when !stop
        if editor instanceof RemoteEditEditor
          @getOrCreateIpdw()
          stop = true

  getOrCreateIpdw: ->
    if @ipdw is undefined
      InterProcessDataWatcher ?= require './model/inter-process-data-watcher'
      fs = require 'fs-plus'
      @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
    else
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
          params = {buffer: buffer, registerEditor: true, host: host, localFile: localFile}
          # copied from workspace.buildTextEditor
          ws = atom.workspace
          params = _.extend({
            config: ws.config, notificationManager: ws.notificationManager, packageManager: ws.packageManager, clipboard: ws.clipboard, viewRegistry: ws.viewRegistry,
            grammarRegistry: ws.grammarRegistry, project: ws.project, assert: ws.assert, applicationDelegate: ws.applicationDelegate
          }, params)
          editor = new RemoteEditEditor(params)
