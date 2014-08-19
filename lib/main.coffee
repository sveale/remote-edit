# Import needed to register deserializer
FileEditorView = require './view/file-editor-view'

module.exports =
  configDefaults:
    showHiddenFiles: false,
    numberOfConcurrentSshQueriesInOneConnection: 5,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    defaultSerializePath: "~/.atom/remoteEdit.json",
    uploadOnSave: true

  createIpdw: ->
    InterProcessDataWatcher = require './model/inter-process-data-watcher'
    fs = require 'fs-plus'
    @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))

  activate: (state) ->
    @createIpdw()
    @setupOpeners()

    atom.workspaceView.command "remote-edit:show-open-files", =>
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
      HostsView = require './view/hosts-view'
      @ipdw.data.then((data) ->
        view = new HostsView()
        view.setItems(data.hostList)
        view.attach()
      )

    atom.workspaceView.command "remote-edit:new-host-sftp", =>
      SftpHost = require './model/sftp-host'
      HostView = require './view/host-view'
      host = new SftpHost()
      view = new HostView(host, @ipdw)
      view.attach()

    atom.workspaceView.command "remote-edit:new-host-ftp", =>
      FtpHost = require './model/ftp-host'
      HostView = require './view/host-view'
      host = new FtpHost()
      view = new HostView(host, @ipdw)
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
      else
        return
