{$, BufferedProcess, EditorView, View} = require 'atom'
Serializable = require 'serializable'
util = require 'util'

HostView = require './view/host-view'
SftpHost = require './model/sftp-host'
FtpHost = require './model/ftp-host'
Host = require './model/host'

module.exports =
class MainView extends View
  Serializable.includeInto(this)
  atom.deserializers.add(this)

  previouslyFocusedElement: null
  hostView: new HostView([]);
  mode: null

  constructor: (@hostList = []) ->
    super

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

  initialize: ()->
    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles()
    atom.workspaceView.command "remote-edit:browse", => @browse()
    atom.workspaceView.command "remote-edit:new-host-sftp", => @newHost("sftp")
    atom.workspaceView.command "remote-edit:new-host-ftp", => @newHost("ftp")
    atom.workspaceView.command "remote-edit:clear-hosts", => @clearHosts()

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


  serializeParams: ->
    {hostList: JSON.stringify(host.serialize() for host in @hostList)}

  deserializeParams: (params) ->
    tmpArray = []
    tmpArray.push(Host.deserialize(host)) for host in JSON.parse(params.hostList)
    params.hostList = tmpArray
    params

  # Tear down any state and detach
  destroy: ->
    @detach()

  detach: ->
    return unless @hasParent()
    @previouslyFocusedElement?.focus()
    super

  browse: ->
    @hostView.setItems(@hostList)
    @hostView.attach()

  newHost: (@mode) ->
    @storeFocusedElement()

    atom.workspaceView.append(this)
    if @mode == 'sftp'
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
    else if @mode == 'ftp'
      @port.setText("21")
      @authenticationButtonsBlock.hide()
      @passwordBlock.show()
      @privateKeyBlock.hide()
    else
      throw new Error('Unsupported mode1')

    @hostName.focus()

  clearHosts: () ->
    @hostList = []
    @restoreFocus()

  confirm: ->
    if @mode == 'sftp'
      newHost = new SftpHost(@hostName.getText(), @directory.getText(), @username.getText(), @port.getText(), null, null, null, null, null, null)
      if @userAgentButton.hasClass('selected')
        newHost.useAgent = true
      else if @privateKeyButton.hasClass('selected')
        newHost.usePrivateKey = true
        newHost.privateKeyPath = @privateKeyPath.getText()
        newHost.passphrase = @privateKeyPassphrase.getText()
      else if @passwordButton.hasClass('selected')
        newHost.usePassword = true
        newHost.password = @password.getText()
      else
        throw new Error('Unvalid option selected')
      @hostList.push(newHost)
    else if @mode == 'ftp'
      newHost = new FtpHost(@hostName.getText(), @directory.getText(), @username.getText(), @port.getText(), @password.getText())
      @hostList.push(newHost)
    else
      throw new Error('Selected mode is not supported!')
    @detach()
    @browse()

  storeFocusedElement: ->
    @previouslyFocusedElement = $(':focus')

  restoreFocus: ->
    if @previouslyFocusedElement?.isOnDom()
      @previouslyFocusedElement.focus()
    else
      atom.workspaceView.focus()
