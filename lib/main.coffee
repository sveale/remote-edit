# Imports needed to register deserializers
FileEditorView = require './view/file-editor-view'
Host = require './model/host'
FtpHost = require './model/ftp-host'
SftpHost = require './model/sftp-host'

module.exports =
  configDefaults:
    showHiddenFiles: false,
    uploadOnSave: true,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    defaultSerializePath: "~/.atom/remoteEdit.json",
    messagePanelTimeout: 5000



  activate: (state) ->
    @setupOpeners()

    atom.workspaceView.command "remote-edit:show-open-files", =>
      @createIpdw() if !@ipdw?

      @ipdw.data.then((data) ->
        localFiles = []
        async = require 'async'
        async.each(data.hostList, ((host, callback) ->
          async.each(host.localFiles, ((file, callback) ->
            file.host = host
            localFiles.push(file)
            ), ((err) -> console.debug err if err?))
          ), ((err) -> console.debug err if err?))
        OpenFilesView = require './view/open-files-view'
        showOpenFilesView = new OpenFilesView(localFiles)
        showOpenFilesView.attach()
      )

    atom.workspaceView.command "remote-edit:browse", =>
      @createIpdw() if !@ipdw?

      HostsView = require './view/hosts-view'
      @ipdw.data.then((data) ->
        view = new HostsView()
        view.setItems(data.hostList)
        view.attach()
      )

    atom.workspaceView.command "remote-edit:new-host-sftp", =>
      @createIpdw() if !@ipdw?

      HostView = require './view/host-view'
      host = new SftpHost()
      view = new HostView(host, @ipdw)
      view.attach()

    atom.workspaceView.command "remote-edit:new-host-ftp", =>
      @createIpdw() if !@ipdw?

      HostView = require './view/host-view'
      host = new FtpHost()
      view = new HostView(host, @ipdw)
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
        host = new SftpHost(parsedUri.hostname, (parsedUri.pathname ? '/'), (parsedUri.auth.split(':')[0] ? parsedUri.auth), (parsedUri.port ? 22), [], true, false, false, (parsedUri.auth.split(':')[1] ? ""), null, null)
      else if parsedUri.protocol is 'ftp:'
        host = new FtpHost(parsedUri.hostname, (parsedUri.pathname ? '/'), (parsedUri.auth.split(':')[0] ? parsedUri.auth), (parsedUri.port ? 21), null, true, (parsedUri.auth.split(':')[1] ? null))

      if host?
        FilesView = require './view/files-view'
        filesView = new FilesView(host)
        filesView.attach()
      else
        return

  createIpdw: ->
    InterProcessDataWatcher = require './model/inter-process-data-watcher'
    fs = require 'fs-plus'
    @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
