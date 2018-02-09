/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
let Editor, RemoteEditEditor;
const path = require('path');
const { resourcePath } = atom.config;
try {
  Editor = require(path.resolve(resourcePath, 'src', 'editor'));
} catch (e) {}
// Catch error
const TextEditor = Editor != null ? Editor : require(path.resolve(resourcePath, 'src', 'text-editor'));

// Defer requiring
let Host = null;
let FtpHost = null;
let SftpHost = null;
let LocalFile = null;
let async = null;
let Dialog = null;
let _ = null;

module.exports =
  class RemoteEditEditor extends TextEditor {

    constructor(params) {
      if (params == null) { params = {}; }
      super(params);
      if (params.host) {
        this.host = params.host;
      }
      if (params.localFile) {
        this.localFile = params.localFile;
      }
    }

    getIconName() {
      return "globe";
    }

    getTitle() {
      let sessionPath;
      if (this.localFile != null) {
        return this.localFile.name;
      } else if ((sessionPath = this.getPath())) {
        return path.basename(sessionPath);
      } else {
        return "undefined";
      }
    }

    getLongTitle() {
      let directory, i, relativePath;
      if (Host == null) { Host = require('./host'); }
      if (FtpHost == null) { FtpHost = require('./ftp-host'); }
      if (SftpHost == null) { SftpHost = require('./sftp-host'); }

      if (i = this.localFile.remoteFile.path.indexOf(this.host.directory) > -1) {
        relativePath = this.localFile.remoteFile.path.slice((i+this.host.directory.length));
      }

      const fileName = this.getTitle();
      if (this.host instanceof SftpHost && (this.host != null) && (this.localFile != null)) {
        directory = (relativePath != null) ? relativePath : `sftp://${this.host.username}@${this.host.hostname}:${this.host.port}${this.localFile.remoteFile.path}`;
      } else if (this.host instanceof FtpHost && (this.host != null) && (this.localFile != null)) {
        directory = (relativePath != null) ? relativePath : `ftp://${this.host.username}@${this.host.hostname}:${this.host.port}${this.localFile.remoteFile.path}`;
      } else {
        directory = atom.project.relativize(path.dirname(sessionPath));
        directory = directory.length > 0 ? directory : path.basename(path.dirname(sessionPath));
      }

      return `${fileName} - ${directory}`;
    }

    onDidSaved(callback) {
      return this.emitter.on('did-saved', callback);
    }

    save() {
      this.buffer.save();
      this.emitter.emit('saved');
      return this.initiateUpload();
    }

    saveAs(filePath) {
      this.buffer.saveAs(filePath);
      this.localFile.path = filePath;
      this.emitter.emit('saved');
      return this.initiateUpload();
    }

    initiateUpload() {
      if (atom.config.get('remote-edit.uploadOnSave')) {
        return this.upload();
      } else {
        if (Dialog == null) { Dialog = require('../view/dialog'); }
        const chosen = atom.confirm({
          message: "File has been saved. Do you want to upload changes to remote host?",
          detailedMessage: "The changes exists on disk and can be uploaded later.",
          buttons: ["Upload", "Cancel"]});
        switch (chosen) {
          case 0: return this.upload();
          case 1: return;
        }
      }
    }

    upload(connectionOptions) {
      if (connectionOptions == null) { connectionOptions = {}; }
      if (async == null) { async = require('async'); }
      if (_ == null) { _ = require('underscore-plus'); }
      if ((this.localFile != null) && (this.host != null)) {
        return async.waterfall([
          callback => {
            if (this.host.usePassword && (connectionOptions.password == null)) {
              if ((this.host.password === "") || (this.host.password === '') || (this.host.password == null)) {
                return async.waterfall([
                  function(callback) {
                    if (Dialog == null) { Dialog = require('../view/dialog'); }
                    const passwordDialog = new Dialog({prompt: "Enter password"});
                    return passwordDialog.toggle(callback);
                  }
                ], (err, result) => {
                  connectionOptions = _.extend({password: result}, connectionOptions);
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
              return this.host.connect(callback, connectionOptions);
            } else {
              return callback(null);
            }
          },
          callback => {
            return this.host.writeFile(this.localFile, callback);
          }
        ], err => {
          if ((err != null) && this.host.usePassword) {
            return async.waterfall([
              function(callback) {
                if (Dialog == null) { Dialog = require('../view/dialog'); }
                const passwordDialog = new Dialog({prompt: "Enter password"});
                return passwordDialog.toggle(callback);
              }
            ], (err, result) => {
              return this.upload({password: result});
            });
          }
        });
      } else {
        return console.error('LocalFile and host not defined. Cannot upload file!');
      }
    }

    serialize() {
      const data = super.serialize(...arguments);
      data.deserializer = 'RemoteEditEditor';
      data.localFile = this.localFile != null ? this.localFile.serialize() : undefined;
      data.host = this.host != null ? this.host.serialize() : undefined;
      return data;
    }

    // mostly copied from TextEditor.deserialize
    static deserialize(state, atomEnvironment) {
      try {
        //console.error  state
        //displayBuffer = TextEditor.deserialize(state.displayBuffer, atomEnvironment)
        state.tokenizedBuffer = TokenizedBuffer.deserialize(state.tokenizedBuffer, atomEnvironment);
        state.tabLength = state.tokenizedBuffer.getTabLength();
      } catch (error) {
        if (error.syscall === 'read') {
          return; // error reading the file, dont deserialize an editor for it
        } else {
          throw error;
        }
      }
      //state.displayBuffer = displayBuffer
      state.buffer = state.tokenizedBuffer.buffer;
      state.registerEditor = true;
      if (state.localFile != null) {
        LocalFile = require('../model/local-file');
        state.localFile = LocalFile.deserialize(state.localFile);
      }
      if (state.host != null) {
        Host = require('../model/host');
        FtpHost = require('../model/ftp-host');
        SftpHost = require('../model/sftp-host');
        state.host = Host.deserialize(state.host);
      }
      // displayBuffer has no getMarkerLayer
      //state.selectionsMarkerLayer = displayBuffer.getMarkerLayer(state.selectionsMarkerLayerId)
      state.config = atomEnvironment.config;
      state.notificationManager = atomEnvironment.notifications;
      state.packageManager = atomEnvironment.packages;
      state.clipboard = atomEnvironment.clipboard;
      state.viewRegistry = atomEnvironment.views;
      state.grammarRegistry = atomEnvironment.grammars;
      state.project = atomEnvironment.project;
      state.assert = atomEnvironment.assert.bind(atomEnvironment);
      state.applicationDelegate = atomEnvironment.applicationDelegate;
      state.autoHeight = false;
      return new (this)(state);
    }
  }
