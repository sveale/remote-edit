/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let OpenFilesView;
const {$$, SelectListView} = require('atom-space-pen-views');
const {CompositeDisposable} = require('atom');

const async = require('async');
const Q = require('q');
const _ = require('underscore-plus');
const fs = require('fs-plus');
const moment = require('moment');

const LocalFile = require('../model/local-file');

module.exports =
  (OpenFilesView = class OpenFilesView extends SelectListView {
    initialize(ipdw) {
      this.ipdw = ipdw;
      super.initialize(...arguments);
      this.addClass('open-files-view');
      this.createItemsFromIpdw();

      this.disposables = new CompositeDisposable;
      this.disposables.add(this.ipdw.onDidChange(() => this.createItemsFromIpdw()));

      this.listenForEvents();
    }

    destroy() {
      if (this.panel != null) { this.panel.destroy(); }
      this.disposables.dispose();
    }

    cancelled() {
      this.hide();
      return this.destroy();
    }

    toggle() {
      if (this.panel && this.panel.isVisible()) {
        this.cancel();
      } else {
        this.show();
      }
    }

    show() {
      if (this.panel == null) { this.panel = atom.workspace.addModalPanel({item: this}); }
      this.panel.show();

      this.storeFocusedElement();

      this.focusFilterEditor();
    }

    hide() {
      this.panel && this.panel.hide();
    }

    getFilterKey() {
      return "name";
    }

    viewForItem(localFile) {
      return $$(function() {
        return this.li({class: 'two-lines'}, () => {
          this.div({class: 'primary-line icon globe'}, `${localFile.host.protocol}://${localFile.host.username}@${localFile.host.hostname}:${localFile.host.port}${localFile.remoteFile.path}`);
          //mtime = moment(fs.statSync(localFile.path).mtime.getTime()).format("HH:mm:ss DD/MM/YY")
          const mtime = moment(fs.stat(localFile.path, stat => stat && stat.mtime && stat.mtime.getTime())).format("HH:mm:ss DD/MM/YY");
          return this.div({class: 'secondary-line no-icon text-subtle'}, `Downloaded: ${localFile.dtime}, Mtime: ${mtime}`);
        });
      });
    }

    confirmed(localFile) {
      const uri = `remote-edit://localFile/?localFile=${encodeURIComponent(JSON.stringify(localFile.serialize()))}&host=${encodeURIComponent(JSON.stringify(localFile.host.serialize()))}`;
      atom.workspace.open(uri, {split: 'left'});
      return this.cancel();
    }

    listenForEvents() {
      return this.disposables.add(atom.commands.add('atom-workspace', 'openfilesview:delete', () => {
        const item = this.getSelectedItem();
        if (item != null) {
          this.items = _.reject(this.items, (val => val === item));
          item.delete();
          return this.setLoading();
        }
      })
      );
    }

    createItemsFromIpdw() {
      return this.ipdw.getData().then(data => {
        const localFiles = [];
        async.each(data.hostList, ((host, callback) =>
          async.each(host.localFiles, (function(file, callback) {
            file.host = host;
            return localFiles.push(file);
            }), (function(err) { if (err != null) { return console.error(err); } }))
          ), (function(err) { if (err != null) { return console.error(err); } }));
        return this.setItems(localFiles);
      });
    }
  });
