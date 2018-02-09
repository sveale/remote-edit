/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let FilesView;
const {$, $$, SelectListView} = require('atom-space-pen-views');
const {CompositeDisposable} = require('atom');
const LocalFile = require('../model/local-file');

const Dialog = require('./dialog');

const fs = require('fs');
const os = require('os');
const async = require('async');
const util = require('util');
const path = require('path');
const Q = require('q');
const _ = require('underscore-plus');
const mkdirp = require('mkdirp');
const moment = require('moment');
const upath = require('upath');

module.exports =
  (FilesView = class FilesView extends SelectListView {
    constructor(...args) {
      super(...args);
      this.updatePath = this.updatePath.bind(this);
      this.openFile = this.openFile.bind(this);
      this.openDirectory = this.openDirectory.bind(this);
    }

    initialize(host) {
      this.host = host;
      super.initialize(...arguments);
      this.addClass('filesview');

      this.disposables = new CompositeDisposable;
      return this.listenForEvents();
    }

    connect(connectionOptions) {
      if (connectionOptions == null) { connectionOptions = {}; }
      this.path = atom.config.get('remote-edit.rememberLastOpenDirectory') && (this.host.lastOpenDirectory != null) ? this.host.lastOpenDirectory : this.host.directory;
      return async.waterfall([
        callback => {
          if (this.host.usePassword && (connectionOptions.password == null)) {
            if ((this.host.password === "") || (this.host.password === '') || (this.host.password == null)) {
              return async.waterfall([
                function(callback) {
                  const passwordDialog = new Dialog({prompt: "Enter password"});
                  return passwordDialog.toggle(callback);
                }
              ], (err, result) => {
                connectionOptions = _.extend({password: result}, connectionOptions);
                this.toggle();
                return callback(null);
              });
            } else {
              return callback(null);
            }
          } else {
            return callback(null);
          }
        },
        callback => {
          if (!this.host.isConnected()) {
            this.setLoading("Connecting...");
            return this.host.connect(callback, connectionOptions);
          } else {
            return callback(null);
          }
        },
        callback => {
          return this.populate(callback);
        }
      ], (err, result) => {
        if (err != null) {
          console.error(err);
          if ((err.code === 450) || (err.type === "PERMISSION_DENIED")) {
            return this.setError("You do not have read permission to what you've specified as the default directory! See the console for more info.");
          } else if ((err.code === 2) && (this.path === this.host.lastOpenDirectory)) {
            // no such file, can occur if lastOpenDirectory is used and the dir has been removed
            this.host.lastOpenDirectory = undefined;
            return this.connect(connectionOptions);
          } else if (this.host.usePassword && ((err.code === 530) || (err.level === "connection-ssh"))) {
            return async.waterfall([
              function(callback) {
                const passwordDialog = new Dialog({prompt: "Enter password"});
                return passwordDialog.toggle(callback);
              }
            ], (err, result) => {
              this.toggle();
              return this.connect({password: result});
            });
          } else {
            return this.setError(err);
          }
        }
      });
    }

    getFilterKey() {
      return "name";
    }

    destroy() {
      if (this.panel != null) { this.panel.destroy(); }
      return this.disposables.dispose();
    }

    cancelled() {
      this.hide();
      if (this.host != null) {
        this.host.close();
      }
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
      if (this.panel != null) {
        this.panel.destroy();
      }
      this.panel = atom.workspace.addModalPanel({item: this});
      this.panel.show();
      this.storeFocusedElement();
      return this.focusFilterEditor();
    }

    hide() {
      return (this.panel != null ? this.panel.hide() : undefined);
    }

    viewForItem(item) {
      return $$(function() {
        return this.li({class: 'two-lines'}, () => {
          if (item.isFile) {
            this.div({class: 'primary-line icon icon-file-text'}, item.name);
          } else if (item.isDir) {
            this.div({class: 'primary-line icon icon-file-directory'}, item.name);
          } else if (item.isLink) {
            this.div({class: 'primary-line icon icon-file-symlink-file'}, item.name);
          }

          return this.div({class: 'secondary-line no-icon text-subtle'}, `Size: ${item.size}, Mtime: ${item.lastModified}, Permissions: ${item.permissions}`);
        });
      });
    }



    populate(callback) {
      return async.waterfall([
        callback => {
          this.setLoading("Loading...");
          return this.host.getFilesMetadata(this.path, callback);
        },
        (items, callback) => {
          if (atom.config.get('remote-edit.foldersOnTop')) { items = _.sortBy(items, 'isFile'); }
          this.setItems(items);
          return callback(undefined, undefined);
        }
      ], (err, result) => {
        if (err != null) { this.setError(err); }
        return (typeof callback === 'function' ? callback(err, result) : undefined);
      });
    }

    populateList() {
      super.populateList(...arguments);
      return this.setError(path.resolve(this.path));
    }

    getNewPath(next) {
      if (this.path[this.path.length - 1] === "/") {
        return this.path + next;
      } else {
        return this.path + "/" + next;
      }
    }

    updatePath(next) {
      return this.path = upath.normalize(this.getNewPath(next));
    }

    getDefaultSaveDirForHostAndFile(file, callback) {
      return async.waterfall([
        callback => fs.realpath(os.tmpDir(), callback),
        function(tmpDir, callback) {
          tmpDir = tmpDir + path.sep + "remote-edit";
          return fs.mkdir(tmpDir, (function(err) {
            if ((err != null) && (err.code === 'EEXIST')) {
              return callback(null, tmpDir);
            } else {
              return callback(err, tmpDir);
            }
            })
          );
        },
        (tmpDir, callback) => {
          tmpDir = tmpDir + path.sep + this.host.hashCode() + '_' + this.host.username + "-" + this.host.hostname +  file.dirName;
          return mkdirp(tmpDir, (function(err) {
            if ((err != null) && (err.code === 'EEXIST')) {
              return callback(null, tmpDir);
            } else {
              return callback(err, tmpDir);
            }
            })
          );
        }
      ], (err, savePath) => callback(err, savePath));
    }

    openFile(file) {
      this.setLoading("Downloading file...");
      const dtime = moment().format("HH:mm:ss DD/MM/YY");
      return async.waterfall([
        callback => {
          return this.getDefaultSaveDirForHostAndFile(file, callback);
        },
        (savePath, callback) => {
          savePath = savePath + path.sep + dtime.replace(/([^a-z0-9\s]+)/gi, '').replace(/([\s]+)/gi, '-') + "_" + file.name;
          const localFile = new LocalFile(savePath, file, dtime, this.host);
          return this.host.getFile(localFile, callback);
        }
      ], (err, localFile) => {
        if (err != null) {
          this.setError(err);
          return console.error(err);
        } else {
          this.host.addLocalFile(localFile);
          const uri = `remote-edit://localFile/?localFile=${encodeURIComponent(JSON.stringify(localFile.serialize()))}&host=${encodeURIComponent(JSON.stringify(localFile.host.serialize()))}`;
          const text = atom.workspace.open(uri, {split: 'left'});
          this.host.close();
          return this.cancel();
        }
      });
    }

    openDirectory(dir) {
      this.setLoading("Opening directory...");
      throw new Error("Not implemented yet!");
    }

    confirmed(item) {
      if (item.isFile) {
        return this.openFile(item);
      } else if (item.isDir) {
        this.filterEditorView.setText('');
        this.setItems();
        this.updatePath(item.name);
        this.host.lastOpenDirectory = upath.normalize(item.path);
        this.host.invalidate();
        return this.populate();
      } else if (item.isLink) {
        if (atom.config.get('remote-edit.followLinks')) {
          this.filterEditorView.setText('');
          this.setItems();
          this.updatePath(item.name);
          return this.populate();
        } else {
          return this.openFile(item);
        }

      } else {
        return this.setError("Selected item is neither a file, directory or link!");
      }
    }

    listenForEvents() {
      return this.disposables.add(atom.commands.add('atom-workspace', 'filesview:open', () => {
        const item = this.getSelectedItem();
        if (item.isFile) {
          return this.openFile(item);
        } else if (item.isDir) {
          return this.openDirectory(item);
        }
      })
      );
    }
  });
