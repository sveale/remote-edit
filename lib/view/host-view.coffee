{$, View, TextEditorView} = require 'atom'

Host = require '../model/host'
SftpHost = require '../model/sftp-host'
FtpHost = require '../model/ftp-host'

fs = require 'fs-plus'

module.exports =
  class HostView extends View
    previouslyFocusedElement: null

    @content: ->
      @div class: 'remote-edit overlay from-top', =>
        @label 'Hostname'
        @subview 'hostname', new TextEditorView(mini: true)

        @label 'Default directory'
        @subview 'directory', new TextEditorView(mini: true)

        @label 'Username'
        @subview 'username', new TextEditorView(mini: true)

        @label 'Port'
        @subview 'port', new TextEditorView(mini: true)

        @label 'Alias (optional)'
        @subview 'alias', new TextEditorView(mini: true)

        @div class: 'block', outlet: 'authenticationButtonsBlock', =>
          @div class: 'btn-group', =>
            @button class: 'btn selected', outlet: 'userAgentButton', 'User agent'
            @button class: 'btn', outlet: 'privateKeyButton', 'Private key'
            @button class: 'btn', outlet: 'passwordButton', 'Password'

        @div class: 'block', outlet: 'passwordBlock', =>
          @label 'Password (leave empty if you want to be prompted)'
          @subview 'password', new TextEditorView(mini: true)

        @div class: 'block', outlet: 'privateKeyBlock', =>
          @label 'Private key path'
          @subview 'privateKeyPath', new TextEditorView(mini: true)
          @label 'Private key passphrase (leave blank if unencrypted)'
          @subview 'privateKeyPassphrase', new TextEditorView(mini: true)

        @div class: 'block', outlet: 'buttonBlock', =>
          @button class: 'inline-block btn pull-right', outlet: 'cancelButton', 'Cancel'
          @button class: 'inline-block btn pull-right', outlet: 'saveButton', 'Save'

    initialize: (@host, @ipdw) ->
      throw new Error("Parameter \"host\" undefined!") if !@host?

      @on 'core:confirm', => @confirm()
      @saveButton.on 'click', => @confirm()

      @on 'core:cancel', => @detach()
      @cancelButton.on 'click', => @detach()

      @alias.setText(@host.alias ? "")
      @hostname.setText(@host.hostname ? "")
      @directory.setText(@host.directory ? "/")
      @username.setText(@host.username ? "")

      @port.setText(@host.port ? "")
      @password.setText(@host.password ? "")
      @privateKeyPath.setText(@host.privateKeyPath ? atom.config.get('remote-edit.sshPrivateKeyPath'))
      @privateKeyPassphrase.setText(@host.passphrase ? "")

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
        @privateKeyPath.focus()

      @passwordButton.on 'click', =>
        @privateKeyButton.toggleClass('selected', false)
        @userAgentButton.toggleClass('selected', false)
        @passwordButton.toggleClass('selected', true)
        @privateKeyBlock.hide()
        @passwordBlock.show()
        @password.focus()



    confirm: ->
      if @host instanceof SftpHost
        @host.useAgent = @userAgentButton.hasClass('selected')
        @host.usePrivateKey = @privateKeyButton.hasClass('selected')
        @host.usePassword = @passwordButton.hasClass('selected')

        if @privateKeyButton.hasClass('selected')
          @host.privateKeyPath = fs.absolute(@privateKeyPath.getText())
          @host.passphrase = @privateKeyPassphrase.getText()
        if @passwordButton.hasClass('selected')
          @host.password = @password.getText()
      else if @host instanceof FtpHost
        @host.usePassword = true
        @host.password = @password.getText()
      else
        throw new Error("\"host\" is not valid type!", @host)

      @host.alias = @alias.getText()
      @host.hostname = @hostname.getText()
      @host.directory = @directory.getText()
      @host.username = @username.getText()
      @host.port = @port.getText()

      if @ipdw?
        @ipdw.data.then((data) =>
          data.hostList.push(@host)
          @ipdw.commit()
        )
      else
        @host.invalidate()
      @detach()


    # Tear down any state and detach
    destroy: ->
      @detach()

    detach: ->
      return unless @hasParent()
      @previouslyFocusedElement?.focus()
      super

    storeFocusedElement: ->
      @previouslyFocusedElement = $(':focus')

    restoreFocus: ->
      if @previouslyFocusedElement?.isOnDom()
        @previouslyFocusedElement.focus()
      else
        atom.workspaceView.focus()

    attach: ->
      atom.workspaceView.append(this)
      @storeFocusedElement()
      @hostname.focus()

      if (@host instanceof SftpHost)
        @authenticationButtonsBlock.show()
        if @host.usePassword
          @passwordButton.click()
        else if @host.usePrivateKey
          @privateKeyButton.click()
        else if @host.useAgent
          @userAgentButton.click()
      else if (@host instanceof FtpHost)
        @authenticationButtonsBlock.hide()
        @passwordBlock.show()
        @privateKeyBlock.hide()
      else
        throw new Error("\"host\" is unknown!", @host)
