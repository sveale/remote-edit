{$, BufferedProcess, EditorView, View} = require 'atom'
{MessagePanelView, PlainMessageView} = require 'atom-message-panel'

util = require 'util'
async = require 'async'
fs = require 'fs-plus'
osenv = require 'osenv'

HostView = require './view/host-view'
OpenFilesView = require './view/open-files-view'
FileEditorView = require './view/file-editor-view'

SftpHost = require './model/sftp-host'
FtpHost = require './model/ftp-host'
Host = require './model/host'

Q = require 'q'

InterProcessDataWatcher = require './model/inter-process-data-watcher'

module.exports =
  class MainView extends View
    previouslyFocusedElement: null
    mode: null
    messages: new MessagePanelView({title: 'Remote edit'})
    hostView: new HostView()

    postMessage: (data) =>
      @messages.attach()
      @messages.add(new PlainMessageView(data))

      closeMessages = () =>
        @messages.clear()
        @messages.close()

      clearInterval(@closeMessagesTimer)
      @closeMessagesTimer = setTimeout(closeMessages, 3000)

    loadInterProcessData: ->
      @ipdw.data.then((data) =>
        async.each(data.hostList, ((item) => @subscribe item, 'info', (info) => @postMessage(info)), null)
        for pane in atom.workspaceView.getPanes()
          for item in pane.getItems()
            if item instanceof FileEditorView
              @subscribe item.host, 'info', (info) => @postMessage(info)
      )

    @content: ->
      @div class: 'remote-edit overlay from-top', =>
        @label 'Hostname'
        @subview 'hostName', new EditorView(mini: true)

        @label 'Default directory'
        @subview 'directory', new EditorView(mini: true)

        @label 'Username'
        @subview 'username', new EditorView(mini: true)

        @label 'Port'
        @subview 'port', new EditorView(mini: true)

        @div class: 'block', outlet: 'authenticationButtonsBlock', =>
          @div class: 'btn-group', =>
            @button class: 'btn selected', outlet: 'userAgentButton', 'User agent'
            @button class: 'btn', outlet: 'privateKeyButton', 'Private key'
            @button class: 'btn', outlet: 'passwordButton', 'Password'

        @div class: 'block', outlet: 'passwordBlock', =>
          @label 'Password (leave empty if you want to be prompted)'
          @subview 'password', new EditorView(mini: true)

        @div class: 'block', outlet: 'privateKeyBlock', =>
          @label 'Private key path'
          @subview 'privateKeyPath', new EditorView(mini: true)
          @label 'Private key passphrase (leave blank if unencrypted)'
          @subview 'privateKeyPassphrase', new EditorView(mini: true)

        @div class: 'block', outlet: 'buttonBlock', =>
          @button class: 'inline-block btn pull-right', outlet: 'cancelButton', 'Cancel'
          @button class: 'inline-block btn pull-right', outlet: 'saveButton', 'Save'

    initialize: ->
      @ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')))
      @subscribe @ipdw, 'contents-changed', => @loadInterProcessData()

      @on 'core:confirm', => @confirm()
      @saveButton.on 'click', => @confirm()

      @on 'core:cancel', => @detach()
      @cancelButton.on 'click', => @detach()

      @directory.setText("/")
      @username.setText(osenv.user())

      @privateKeyPath.setText(atom.config.get('remote-edit.sshPrivateKeyPath'))
      @privateKeyPassphrase.setText("")

      @userAgentButton.on 'click', =>
        @privateKeyButton.toggleClass('selected', false)
        @userAgentButton.toggleClass('selected', true)
        @passwordButton.toggleClass('selected', false)
        @passwordBlock.hide()
        @privateKeyBlock.hide()

      @privateKeyButton.on 'click', =>
        @privateKeyButton.toggleClass('selected', true)
        @userAgentButton.toggleClass('selected', false)
        @passwordButton.toggleClass('selected', false)
        @passwordBlock.hide()
        @privateKeyBlock.show()

      @passwordButton.on 'click', =>
        @privateKeyButton.toggleClass('selected', false)
        @userAgentButton.toggleClass('selected', false)
        @passwordButton.toggleClass('selected', true)
        @privateKeyBlock.hide()
        @passwordBlock.show()

    # Tear down any state and detach
    destroy: ->
      @detach()

    detach: ->
      return unless @hasParent()
      @previouslyFocusedElement?.focus()
      super

    browse: ->
      @ipdw.data.then((data) =>
        @hostView.setItems(data.hostList)
        @hostView.attach()
      )

    showOpenFiles: ->
      localFiles = []
      @ipdw.data.then((data) =>
        async.each(data.hostList, ((host, callback) ->
          async.each(host.localFiles, ((file, callback) ->
            file.host = host
            localFiles.push(file)
            ), ((err) -> console.debug err if err?))
          ), ((err) -> console.debug err if err?))
        showOpenFilesView = new OpenFilesView(localFiles)
        showOpenFilesView.attach()
      )


    newHost: (@mode) ->
      @storeFocusedElement()

      atom.workspaceView.append(this)
      if @mode == 'sftp'
        @port.setText("22")
        @authenticationButtonsBlock.show()
        @passwordBlock.hide()
        @privateKeyBlock.hide()
        @userAgentButton.click()
      else if @mode == 'ftp'
        @port.setText("21")
        @authenticationButtonsBlock.hide()
        @passwordBlock.show()
        @privateKeyBlock.hide()
      else
        throw new Error('Unsupported mode1')

      @hostName.focus()

    confirm: ->
      newHost = null
      if @mode == 'sftp'
        newHost = new SftpHost(@hostName.getText(), @directory.getText(), @username.getText(), @port.getText(), null, null, null, null, null, null, null)
        if @userAgentButton.hasClass('selected')
          newHost.useAgent = true
        else if @privateKeyButton.hasClass('selected')
          newHost.usePrivateKey = true
          newHost.privateKeyPath = fs.absolute(@privateKeyPath.getText())
          newHost.passphrase = @privateKeyPassphrase.getText()
        else if @passwordButton.hasClass('selected')
          newHost.usePassword = true
          newHost.password = @password.getText()
        else
          throw new Error('Unvalid option selected')
      else if @mode == 'ftp'
        newHost = new FtpHost(@hostName.getText(), @directory.getText(), @username.getText(), @port.getText(), null, true, @password.getText())
      else
        throw new Error('Selected mode is not supported!')

      @subscribe newHost, 'info', (data) => @postMessage(data)
      @ipdw.data.then((data) =>
        data.addSubscriptionToHost(newHost)
        data.hostList.push(newHost)
        @ipdw.commit()
        @detach()
        @browse()
      )

    storeFocusedElement: ->
      @previouslyFocusedElement = $(':focus')

    restoreFocus: ->
      if @previouslyFocusedElement?.isOnDom()
        @previouslyFocusedElement.focus()
      else
        atom.workspaceView.focus()
