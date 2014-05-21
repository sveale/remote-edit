{$, BufferedProcess, EditorView, View} = require 'atom'

HostView = require './view/host-view'
SftpHost = require './model/sftp-host'
FtpHost = require './model/ftp-host'

module.exports =
class MainView extends View
  previouslyFocusedElement: null
  hostView: new HostView([]);
  hostList: []

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
        @label 'Password'
        @subview 'password', new EditorView(mini: true)

      @div class: 'block', outlet: 'privateKeyBlock', =>
        @label 'Private key path'
        @subview 'privateKeyPath', new EditorView(mini: true)
        @label 'Private key passphrase (leave blank if unencrypted)'
        @subview 'privateKeyPassphrase', new EditorView(mini: true)

  initialize: (serializeState) ->
    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles()
    atom.workspaceView.command "remote-edit:browse", => @browse()
    atom.workspaceView.command "remote-edit:new-host-sftp", => @newHost("sftp")
    atom.workspaceView.command "remote-edit:new-host-ftp", => @newHost("ftp")

    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    @directory.setText("/")
    @username.setText(process.env['USER'])

    @privateKeyPath.setText(atom.config.get('remote-edit.sshPrivateKeyPath'))
    @privateKeyPassphrase.setText(atom.config.get('remote-edit.sshPrivateKeyPassphrase'))

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


  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  detach: ->
    return unless @hasParent()
    @previouslyFocusedElement?.focus()
    super

  browse: ->
    ***REMOVED*** = new SftpHost("***REMOVED***", "/", "sverre", 22, true, false, false, null, null, null)
    ***REMOVED***2 = new SftpHost("***REMOVED***", "/", "sverre", 22, true, false, false, null, null, null)
    ***REMOVED***Ftp = new FtpHost("***REMOVED***", "/", "sverre", "21", "asdf")
    leetnettFtp = new FtpHost("***REMOVED***", "/", "sverre", "21", "asdf")

    @hostView.setItems([***REMOVED***, ***REMOVED***2, ***REMOVED***Ftp, leetnettFtp])
    @hostView.attach()

  newHost: (protocol) ->
    @previouslyFocusedElement = $(':focus')

    atom.workspaceView.append(this)
    if protocol == 'sftp'
      @port.setText("22")
      @authenticationButtonsBlock.show()
      @passwordBlock.hide()
      @privateKeyBlock.hide()
      if atom.config.get 'remote-edit.sshUseUserAgent'
        @userAgentButton.click()
      else if atom.config.get 'remote-edit.sshUsePrivateKey'
        @privateKeyButton.click()
      else
        @passwordButton.click()

    else if protocol == 'ftp'
      @port.setText("21")
      @authenticationButtonsBlock.hide()
      @passwordBlock.show()
      @privateKeyBlock.hide()
    else
      console.debug 'asdf'

    @hostName.focus()


  confirm: ->
    @detach()
    @browse()
