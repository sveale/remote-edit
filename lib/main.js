/*
 * decaffeinated and cleaned up
 */
const _ = require('underscore-plus');
// Import needed to register deserializer
const RemoteEditEditor = require('./model/remote-edit-editor');

// Deferred requirements
let OpenFilesView = null;
let HostView = null;
let HostsView = null;
let Host = null;
let SftpHost = null;
let FtpHost = null;
let LocalFile = null;
let url = null;
let Q = null;
let InterProcessDataWatcher = null;
let fs = null;

module.exports = {
  config: {
    showHiddenFiles: {
      title: 'Show hidden files',
      type: 'boolean',
      default: false
    },
    uploadOnSave: {
      title: 'Upload on save',
      description: 'When enabled, remote files will be automatically uploaded when saved',
      type: 'boolean',
      default: true
    },
    notifications: {
      title: 'Display notifications',
      type: 'boolean',
      default: true
    },
    sshPrivateKeyPath: {
      title: 'Path to private SSH key',
      type: 'string',
      default: '~/.ssh/id_rsa'
    },
    defaultSerializePath: {
      title: 'Default path to serialize remoteEdit data',
      type: 'string',
      default: '~/.atom/remoteEdit.json'
    },
    agentToUse: {
      title: 'SSH agent',
      description: 'Overrides default SSH agent. See ssh2 docs for more info.',
      type: 'string',
      default: 'Default'
    },
    foldersOnTop: {
      title: 'Show folders on top',
      type: 'boolean',
      default: false
    },
    followLinks: {
      title: 'Follow symbolic links',
      description: 'If set to true, symbolic links are treated as directories',
      type: 'boolean',
      default: true
    },
    clearFileList: {
      title: 'Clear file list',
      description: 'When enabled, the open files list will be cleared on initialization',
      type: 'boolean',
      default: false
    },
    rememberLastOpenDirectory: {
      title: 'Remember last open directory',
      description: 'When enabled, browsing a host will return you to the last directory you entered',
      type: 'boolean',
      default: false
    },
    storePasswordsUsingKeytar: {
      title: 'Store passwords using node-keytar',
      description: 'When enabled, passwords and passphrases will be stored in system\'s keychain',
      type: 'boolean',
      default: false
    },
    filterHostsUsing: {
      type: 'object',
      properties: {
        hostname: {
          type: 'boolean',
          default: true
        },
        alias: {
          type: 'boolean',
          default: false
        },
        username: {
          type: 'boolean',
          default: false
        },
        port: {
          type: 'boolean',
          default: false
        }
      }
    }
  },


  activate(state) {
    this.setupOpeners();
    this.initializeIpdwIfNecessary();

    atom.commands.add('atom-workspace', 'remote-edit:show-open-files', () => this.showOpenFiles());
    atom.commands.add('atom-workspace', 'remote-edit:browse', () => this.browse());
    atom.commands.add('atom-workspace', 'remote-edit:new-host-sftp', () => this.newHostSftp());
    return atom.commands.add('atom-workspace', 'remote-edit:new-host-ftp', () => this.newHostFtp());
  },

  deactivate() {
    if (this.ipdw != null) { this.ipdw.destroy(); }
  },

  deserializeRemoteEditor() {
    return data => new RemoteEditEditor(data);
  },

  newHostSftp() {
    if (HostView == null) { HostView = require('./view/host-view'); }
    if (SftpHost == null) { SftpHost = require('./model/sftp-host'); }
    const host = new SftpHost();
    const view = new HostView(host, this.getOrCreateIpdw());
    view.toggle();
  },

  newHostFtp() {
    if (HostView == null) { HostView = require('./view/host-view'); }
    if (FtpHost == null) { FtpHost = require('./model/ftp-host'); }
    const host = new FtpHost();
    const view = new HostView(host, this.getOrCreateIpdw());
    view.toggle();
  },

  browse() {
    if (HostsView == null) { HostsView = require('./view/hosts-view'); }
    const view = new HostsView(this.getOrCreateIpdw());
    view.toggle();
  },

  showOpenFiles() {
    if (OpenFilesView == null) { OpenFilesView = require('./view/open-files-view'); }
    const showOpenFilesView = new OpenFilesView(this.getOrCreateIpdw());
    showOpenFilesView.toggle();
  },

  initializeIpdwIfNecessary() {
    if (atom.config.get('remote-edit.notifications')) {
      let stop = false;
      const result = [];
      for (let editor of Array.from(atom.workspace.getTextEditors())) {
        if (!stop) {
          if (editor instanceof RemoteEditEditor) {
            this.getOrCreateIpdw();
            result.push(stop = true);
          } else {
            result.push(undefined);
          }
        }
      }
      return result;
    }
  },

  getOrCreateIpdw() {
    if (this.ipdw === undefined) {
      if (InterProcessDataWatcher == null) { InterProcessDataWatcher = require('./model/inter-process-data-watcher'); }
      fs = require('fs-plus');
      return this.ipdw = new InterProcessDataWatcher(fs.absolute(atom.config.get('remote-edit.defaultSerializePath')));
    } else {
      return this.ipdw;
    }
  },

  setupOpeners() {
    return atom.workspace.addOpener(function(uriToOpen) {
      let host, protocol, query;
      if (url == null) { url = require('url'); }
      try {
        ({protocol, host, query} = url.parse(uriToOpen, true));
      } catch (error) {
        return;
      }
      if (protocol !== 'remote-edit:') { return; }

      if (host === 'localfile') {
        if (Q == null) { Q = require('q'); }
        if (Host == null) { Host = require('./model/host'); }
        if (FtpHost == null) { FtpHost = require('./model/ftp-host'); }
        if (SftpHost == null) { SftpHost = require('./model/sftp-host'); }
        if (LocalFile == null) { LocalFile = require('./model/local-file'); }
        const localFile = LocalFile.deserialize(JSON.parse(decodeURIComponent(query.localFile)));
        host = Host.deserialize(JSON.parse(decodeURIComponent(query.host)));

        return atom.project.bufferForPath(localFile.path).then(function(buffer) {
          let editor;
          let params = {buffer, registerEditor: true, host, localFile};
          // copied from workspace.buildTextEditor
          const ws = atom.workspace;
          params = _.extend({
            config: ws.config, notificationManager: ws.notificationManager, packageManager: ws.packageManager, clipboard: ws.clipboard, viewRegistry: ws.viewRegistry,
            grammarRegistry: ws.grammarRegistry, project: ws.project, assert: ws.assert, applicationDelegate: ws.applicationDelegate, autoHeight: false}
          , params);
          return editor = new RemoteEditEditor(params);
        });
      }
    });
  }
};



//          params = Object.assign({assert: this.assert}, params)

//          let scope = null
//          if (params.buffer) {
//            const filePath = params.buffer.getPath()
//            const headContent = params.buffer.getTextInRange(GRAMMAR_SELECTION_RANGE)
//            params.grammar = ws.grammarRegistry
//            scope = new ScopeDescriptor({scopes: [params.grammar.scopeName]})
//          }

//          Object.assign(params, this.textEditorParamsForScope(scope))
//          editor = new RemoteEditEditor(params)
//          const subscriptions = new CompositeDisposable(
//            this.textEditorRegistry.maintainGrammar(editor),
//            this.textEditorRegistry.maintainConfig(editor)
//          )
//          editor.onDidDestroy(() => { subscriptions.dispose() })
//          return editor
