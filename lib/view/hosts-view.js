/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let HostsView;
const {$, $$, SelectListView} = require('atom-space-pen-views');
const {CompositeDisposable, Emitter} = require('atom');
const _ = require('underscore-plus');

const FilesView = require('./files-view');
const HostView = require('./host-view');

const SftpHost = require('../model/sftp-host');
const FtpHost = require('../model/ftp-host');

module.exports =
  (HostsView = class HostsView extends SelectListView {
    initialize(ipdw) {
      this.ipdw = ipdw;
      super.initialize(...arguments);
      this.createItemsFromIpdw();
      this.addClass('hosts-view');

      this.disposables = new CompositeDisposable;
      this.disposables.add(this.ipdw.onDidChange(() => this.createItemsFromIpdw()));

      return this.listenForEvents();
    }

    destroy() {
      if (this.panel != null) { this.panel.destroy(); }
      return this.disposables.dispose();
    }

    cancelled() {
      this.hide();
      return this.destroy();
    }

    toggle() {
      if ((this.panel != null ? this.panel.isVisible() : undefined)) {
        return this.cancel();
      } else {
        return this.show();
      }
    }

    show() {
      if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this}); }
      this.panel.show();

      this.storeFocusedElement();

      return this.focusFilterEditor();
    }

    hide() {
      return (this.panel != null ? this.panel.hide() : undefined);
    }

    getFilterKey() {
      return "searchKey";
    }

    viewForItem(item) {
      const { keyBindings } = this;

      return $$(function() {
        return this.li({class: 'two-lines'}, () => {
          let authType;
          this.div({class: 'primary-line'}, () => {
            if (item.alias != null) { this.span({class: 'inline-block highlight'}, `${item.alias}`); }
            return this.span({class: 'inline-block'}, `${item.username}@${item.hostname}:${item.port}:${item.directory}`);
          });
          if (item instanceof SftpHost) {
            authType = "not set";
            if (item.usePassword && ((item.password === "") || (item.password === '') || (item.password == null))) {
              authType = "password (not set)";
            } else if (item.usePassword) {
              authType = "password (set)";
            } else if (item.usePrivateKey) {
              authType = "key";
            } else if (item.useAgent) {
              authType = "agent";
            }
            return this.div({class: "secondary-line"}, `Type: SFTP, Open files: ${item.localFiles.length}, Auth: ` + authType);
          } else if (item instanceof FtpHost) {
            authType = "not set";
            if (item.usePassword && ((item.password === "") || (item.password === '') || (item.password == null))) {
              authType = "password (not set)";
            } else {
              authType = "password (set)";
            }
            return this.div({class: "secondary-line"}, `Type: FTP, Open files: ${item.localFiles.length}, Auth: ` + authType);
          } else {
            return this.div({class: "secondary-line"}, "Type: UNDEFINED");
          }
        });
      });
    }

    confirmed(item) {
      this.cancel();
      const filesView = new FilesView(item);
      filesView.connect();
      return filesView.toggle();
    }

    listenForEvents() {
      this.disposables.add(atom.commands.add('atom-workspace', 'hostview:delete', () => {
        const item = this.getSelectedItem();
        if (item != null) {
          item.delete();
          return this.setLoading();
        }
      })
      );
      return this.disposables.add(atom.commands.add('atom-workspace', 'hostview:edit', () => {
        const item = this.getSelectedItem();
        if (item != null) {
          const hostView = new HostView(item);
          hostView.toggle();
          return this.cancel();
        }
      })
      );
    }

    createItemsFromIpdw() {
      return this.ipdw.getData().then(resolved => this.setItems(resolved.hostList));
    }
  });
