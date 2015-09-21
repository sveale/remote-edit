{$, View, TextEditorView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

Host = require '../model/host'
SftpHost = require '../model/sftp-host'
FtpHost = require '../model/ftp-host'

fs = require 'fs-plus'

try
  keytar = require 'keytar'
catch err
  console.debug 'Keytar could not be loaded! Passwords will be stored in cleartext to remoteEdit.json!'
  keytar = undefined

module.exports =
  class HostView extends View
    @content: ->
      @div class: 'host-view', =>
        @h2 "Connection settings", class: "host-header"
        @label 'Hostname:'
        @subview 'hostname', new TextEditorView(mini: true)

        @label 'Default directory:'
        @subview 'directory', new TextEditorView(mini: true)

        @label 'Username:'
        @subview 'username', new TextEditorView(mini: true)

        @label 'Port:'
        @subview 'port', new TextEditorView(mini: true)


        @h2 "Authentication settings", class: "host-header"
        @div class: 'block', outlet: 'authenticationButtonsBlock', =>
          @div class: 'btn-group', =>
            @button class: 'btn selected', outlet: 'userAgentButton', click: 'userAgentButtonClick', 'User agent'
            @button class: 'btn', outlet: 'privateKeyButton', click: 'privateKeyButtonClick', 'Private key'
            @button class: 'btn', outlet: 'passwordButton', click: 'passwordButtonClick', 'Password'

        @div class: 'block', outlet: 'passwordBlock', =>
          @label 'Password:'
          @subview 'password', new TextEditorView(mini: true)
          @label 'Passwords are by default stored in cleartext! Leave password field empty if you want to be prompted.', class: 'text-warning'
          @label 'Passwords can be saved to default system keychain by enabling option in settings.', class: 'text-warning'

        @div class: 'block', outlet: 'privateKeyBlock', =>
          @label 'Private key path:'
          @subview 'privateKeyPath', new TextEditorView(mini: true)
          @label 'Private key passphrase:'
          @subview 'privateKeyPassphrase', new TextEditorView(mini: true)
          @label 'Passphrases are by default stored in cleartext! Leave Passphrases field empty if you want to be prompted.', class: 'text-warning'
          @label 'Passphrases can be saved to default system keychain by enabling option in settings.', class: 'text-warning'

        @h2 "Additional settings", class: "host-header"
        @label 'Alias:'
        @subview 'alias', new TextEditorView(mini: true)



        @div class: 'block', outlet: 'buttonBlock', =>
          @button class: 'inline-block btn pull-right', outlet: 'cancelButton', click: 'cancel', 'Cancel'
          @button class: 'inline-block btn pull-right', outlet: 'saveButton', click: 'confirm','Save'

    initialize: (@host, @ipdw) ->
      throw new Error("Parameter \"host\" undefined!") if !@host?

      @disposables = new CompositeDisposable
      @disposables.add atom.commands.add 'atom-workspace',
        'core:confirm': => @confirm()
        'core:cancel': (event) =>
          @cancel()
          event.stopPropagation()

      @alias.setText(@host.alias ? "")
      @hostname.setText(@host.hostname ? "")
      @directory.setText(@host.directory ? "/")
      @username.setText(@host.username ? "")

      @port.setText(@host.port ? "")

      if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (keytar?)
        keytarPassword = keytar.getPassword(@host.getServiceNamePassword(), @host.getServiceAccount())
        @password.setText(keytarPassword ? "")
      else
        @password.setText(@host.password ? "")

      @privateKeyPath.setText(@host.privateKeyPath ? atom.config.get('remote-edit.sshPrivateKeyPath'))
      if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@host instanceof SftpHost) and (keytar?)
        keytarPassphrase = keytar.getPassword(@host.getServiceNamePassphrase(), @host.getServiceAccount())
        @privateKeyPassphrase.setText(keytarPassphrase ? "")
      else
        @privateKeyPassphrase.setText(@host.passphrase ? "")

    userAgentButtonClick: ->
      @privateKeyButton.toggleClass('selected', false)
      @userAgentButton.toggleClass('selected', true)
      @passwordButton.toggleClass('selected', false)
      @passwordBlock.hide()
      @privateKeyBlock.hide()

    privateKeyButtonClick: ->
      @privateKeyButton.toggleClass('selected', true)
      @userAgentButton.toggleClass('selected', false)
      @passwordButton.toggleClass('selected', false)
      @passwordBlock.hide()
      @privateKeyBlock.show()
      @privateKeyPath.focus()

    passwordButtonClick: ->
      @privateKeyButton.toggleClass('selected', false)
      @userAgentButton.toggleClass('selected', false)
      @passwordButton.toggleClass('selected', true)
      @privateKeyBlock.hide()
      @passwordBlock.show()
      @password.focus()


    confirm: ->
      @cancel()

      @host.alias = @alias.getText()
      @host.hostname = @hostname.getText()
      @host.directory = @directory.getText()
      @host.username = @username.getText()
      @host.port = @port.getText()

      if @host instanceof SftpHost
        @host.useAgent = @userAgentButton.hasClass('selected')
        @host.usePrivateKey = @privateKeyButton.hasClass('selected')
        @host.usePassword = @passwordButton.hasClass('selected')

        if @privateKeyButton.hasClass('selected')
          @host.privateKeyPath = fs.absolute(@privateKeyPath.getText())
          if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@privateKeyPassphrase.getText().length > 0) and (keytar?)
            keytar.replacePassword(@host.getServiceNamePassphrase(), @host.getServiceAccount(), @privateKeyPassphrase.getText())
            @host.passphrase = "***** keytar *****"
          else if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@privateKeyPassphrase.getText().length is 0)
            keytar.deletePassword(@host.getServiceNamePassphrase(), @host.getServiceAccount())
            @host.passphrase = ""
          else
            @host.passphrase = @privateKeyPassphrase.getText()
        if @passwordButton.hasClass('selected')
          if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@password.getText().length > 0) and (keytar?)
            keytarResult = keytar.replacePassword(@host.getServiceNamePassword(), @host.getServiceAccount(), @password.getText())
            @host.password = "***** keytar *****"
          else if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@password.getText().length is 0) and (keytar?)
            keytar.deletePassword(@host.getServiceNamePassword(), @host.getServiceAccount())
            @host.password = ""
          else
            @host.password = @password.getText()
      else if @host instanceof FtpHost
        @host.usePassword = true
        if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@password.getText().length > 0) and (keytar?)
          keytarResult = keytar.replacePassword(@host.getServiceNamePassword(), @host.getServiceAccount(), @password.getText())
          @host.password = "***** keytar *****"
        else if atom.config.get('remote-edit.storePasswordsUsingKeytar') and (@password.getText().length is 0) and (keytar?)
          keytar.deletePassword(@host.getServiceNamePassword(), @host.getServiceAccount())
          @host.password = ""
        else
          @host.password = @password.getText()
      else
        throw new Error("\"host\" is not valid type!", @host)



      if @ipdw?
        @ipdw.getData().then((data) =>
          data.addNewHost(@host)
        )
      else
        @host.invalidate()

    destroy: ->
      @panel.destroy() if @panel?
      @disposables.dispose()

    cancel: ->
      @cancelled()
      @restoreFocus()
      @destroy()

    cancelled: ->
      @hide()

    toggle: ->
      if @panel?.isVisible()
        @cancel()
      else
        @show()

    show: ->
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

      @panel ?= atom.workspace.addModalPanel(item: this)
      @panel.show()

      @storeFocusedElement()
      @hostname.focus()

    hide: ->
      @panel?.hide()

    storeFocusedElement: ->
      @previouslyFocusedElement = $(document.activeElement)

    restoreFocus: ->
      @previouslyFocusedElement?.focus()
