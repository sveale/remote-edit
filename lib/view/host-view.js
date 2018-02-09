/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let HostView, keytar;
const {$, View, TextEditorView} = require('atom-space-pen-views');
const {CompositeDisposable} = require('atom');

const Host = require('../model/host');
const SftpHost = require('../model/sftp-host');
const FtpHost = require('../model/ftp-host');

const fs = require('fs-plus');

try {
  keytar = require('keytar');
} catch (err) {
  console.debug('Keytar could not be loaded! Passwords will be stored in cleartext to remoteEdit.json!');
  keytar = undefined;
}

module.exports =
  (HostView = class HostView extends View {
    static content() {
      return this.div({class: 'host-view'}, () => {
        this.h2("Connection settings", {class: "host-header"});
        this.label('Hostname:');
        this.subview('hostname', new TextEditorView({mini: true}));

        this.label('Default directory:');
        this.subview('directory', new TextEditorView({mini: true}));

        this.label('Username:');
        this.subview('username', new TextEditorView({mini: true}));

        this.label('Port:');
        this.subview('port', new TextEditorView({mini: true}));


        this.h2("Authentication settings", {class: "host-header"});
        this.div({class: 'block', outlet: 'authenticationButtonsBlock'}, () => {
          return this.div({class: 'btn-group'}, () => {
            this.button({class: 'btn selected', outlet: 'userAgentButton', click: 'userAgentButtonClick'}, 'User agent');
            this.button({class: 'btn', outlet: 'privateKeyButton', click: 'privateKeyButtonClick'}, 'Private key');
            return this.button({class: 'btn', outlet: 'passwordButton', click: 'passwordButtonClick'}, 'Password');
          });
        });

        this.div({class: 'block', outlet: 'passwordBlock'}, () => {
          this.label('Password:');
          this.subview('password', new TextEditorView({mini: true}));
          this.label('Passwords are by default stored in cleartext! Leave password field empty if you want to be prompted.', {class: 'text-warning'});
          return this.label('Passwords can be saved to default system keychain by enabling option in settings.', {class: 'text-warning'});
        });

        this.div({class: 'block', outlet: 'privateKeyBlock'}, () => {
          this.label('Private key path:');
          this.subview('privateKeyPath', new TextEditorView({mini: true}));
          this.label('Private key passphrase:');
          this.subview('privateKeyPassphrase', new TextEditorView({mini: true}));
          this.label('Passphrases are by default stored in cleartext! Leave Passphrases field empty if you want to be prompted.', {class: 'text-warning'});
          return this.label('Passphrases can be saved to default system keychain by enabling option in settings.', {class: 'text-warning'});
        });

        this.h2("Additional settings", {class: "host-header"});
        this.label('Alias:');
        this.subview('alias', new TextEditorView({mini: true}));



        return this.div({class: 'block', outlet: 'buttonBlock'}, () => {
          this.button({class: 'inline-block btn pull-right', outlet: 'cancelButton', click: 'cancel'}, 'Cancel');
          return this.button({class: 'inline-block btn pull-right', outlet: 'saveButton', click: 'confirm'},'Save');
        });
      });
    }

    initialize(host, ipdw) {
      this.host = host;
      this.ipdw = ipdw;
      if ((this.host == null)) { throw new Error("Parameter \"host\" undefined!"); }

      this.disposables = new CompositeDisposable;
      this.disposables.add(atom.commands.add('atom-workspace', {
        'core:confirm': () => this.confirm(),
        'core:cancel': event => {
          this.cancel();
          return event.stopPropagation();
        }
      }
      )
      );

      this.alias.setText(this.host.alias != null ? this.host.alias : "");
      this.hostname.setText(this.host.hostname != null ? this.host.hostname : "");
      this.directory.setText(this.host.directory != null ? this.host.directory : "/");
      this.username.setText(this.host.username != null ? this.host.username : "");

      this.port.setText(this.host.port != null ? this.host.port : "");

      if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (keytar != null)) {
        const keytarPassword = keytar.getPassword(this.host.getServiceNamePassword(), this.host.getServiceAccount());
        this.password.setText(keytarPassword != null ? keytarPassword : "");
      } else {
        this.password.setText(this.host.password != null ? this.host.password : "");
      }

      this.privateKeyPath.setText(this.host.privateKeyPath != null ? this.host.privateKeyPath : atom.config.get('remote-edit.sshPrivateKeyPath'));
      if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.host instanceof SftpHost) && (keytar != null)) {
        const keytarPassphrase = keytar.getPassword(this.host.getServiceNamePassphrase(), this.host.getServiceAccount());
        return this.privateKeyPassphrase.setText(keytarPassphrase != null ? keytarPassphrase : "");
      } else {
        return this.privateKeyPassphrase.setText(this.host.passphrase != null ? this.host.passphrase : "");
      }
    }

    userAgentButtonClick() {
      this.privateKeyButton.toggleClass('selected', false);
      this.userAgentButton.toggleClass('selected', true);
      this.passwordButton.toggleClass('selected', false);
      this.passwordBlock.hide();
      return this.privateKeyBlock.hide();
    }

    privateKeyButtonClick() {
      this.privateKeyButton.toggleClass('selected', true);
      this.userAgentButton.toggleClass('selected', false);
      this.passwordButton.toggleClass('selected', false);
      this.passwordBlock.hide();
      this.privateKeyBlock.show();
      return this.privateKeyPath.focus();
    }

    passwordButtonClick() {
      this.privateKeyButton.toggleClass('selected', false);
      this.userAgentButton.toggleClass('selected', false);
      this.passwordButton.toggleClass('selected', true);
      this.privateKeyBlock.hide();
      this.passwordBlock.show();
      return this.password.focus();
    }


    confirm() {
      let keytarResult;
      this.cancel();

      this.host.alias = this.alias.getText();
      this.host.hostname = this.hostname.getText();
      this.host.directory = this.directory.getText();
      this.host.username = this.username.getText();
      this.host.port = this.port.getText();

      if (this.host instanceof SftpHost) {
        this.host.useAgent = this.userAgentButton.hasClass('selected');
        this.host.usePrivateKey = this.privateKeyButton.hasClass('selected');
        this.host.usePassword = this.passwordButton.hasClass('selected');

        if (this.privateKeyButton.hasClass('selected')) {
          this.host.privateKeyPath = fs.absolute(this.privateKeyPath.getText());
          if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.privateKeyPassphrase.getText().length > 0) && (keytar != null)) {
            keytar.replacePassword(this.host.getServiceNamePassphrase(), this.host.getServiceAccount(), this.privateKeyPassphrase.getText());
            this.host.passphrase = "***** keytar *****";
          } else if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.privateKeyPassphrase.getText().length === 0)) {
            keytar.deletePassword(this.host.getServiceNamePassphrase(), this.host.getServiceAccount());
            this.host.passphrase = "";
          } else {
            this.host.passphrase = this.privateKeyPassphrase.getText();
          }
        }
        if (this.passwordButton.hasClass('selected')) {
          if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.password.getText().length > 0) && (keytar != null)) {
            keytarResult = keytar.replacePassword(this.host.getServiceNamePassword(), this.host.getServiceAccount(), this.password.getText());
            this.host.password = "***** keytar *****";
          } else if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.password.getText().length === 0) && (keytar != null)) {
            keytar.deletePassword(this.host.getServiceNamePassword(), this.host.getServiceAccount());
            this.host.password = "";
          } else {
            this.host.password = this.password.getText();
          }
        }
      } else if (this.host instanceof FtpHost) {
        this.host.usePassword = true;
        if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.password.getText().length > 0) && (keytar != null)) {
          keytarResult = keytar.replacePassword(this.host.getServiceNamePassword(), this.host.getServiceAccount(), this.password.getText());
          this.host.password = "***** keytar *****";
        } else if (atom.config.get('remote-edit.storePasswordsUsingKeytar') && (this.password.getText().length === 0) && (keytar != null)) {
          keytar.deletePassword(this.host.getServiceNamePassword(), this.host.getServiceAccount());
          this.host.password = "";
        } else {
          this.host.password = this.password.getText();
        }
      } else {
        throw new Error("\"host\" is not valid type!", this.host);
      }



      if (this.ipdw != null) {
        return this.ipdw.getData().then(data => {
          return data.addNewHost(this.host);
        });
      } else {
        return this.host.invalidate();
      }
    }

    destroy() {
      if (this.panel != null) { this.panel.destroy(); }
      return this.disposables.dispose();
    }

    cancel() {
      this.cancelled();
      this.restoreFocus();
      return this.destroy();
    }

    cancelled() {
      return this.hide();
    }

    toggle() {
      if ((this.panel != null ? this.panel.isVisible() : undefined)) {
        return this.cancel();
      } else {
        return this.show();
      }
    }

    show() {
      if (this.host instanceof SftpHost) {
        this.authenticationButtonsBlock.show();
        if (this.host.usePassword) {
          this.passwordButton.click();
        } else if (this.host.usePrivateKey) {
          this.privateKeyButton.click();
        } else if (this.host.useAgent) {
          this.userAgentButton.click();
        }
      } else if (this.host instanceof FtpHost) {
        this.authenticationButtonsBlock.hide();
        this.passwordBlock.show();
        this.privateKeyBlock.hide();
      } else {
        throw new Error("\"host\" is unknown!", this.host);
      }

      if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this}); }
      this.panel.show();

      this.storeFocusedElement();
      return this.hostname.focus();
    }

    hide() {
      return (this.panel != null ? this.panel.hide() : undefined);
    }

    storeFocusedElement() {
      return this.previouslyFocusedElement = $(document.activeElement);
    }

    restoreFocus() {
      return (this.previouslyFocusedElement != null ? this.previouslyFocusedElement.focus() : undefined);
    }
  });
