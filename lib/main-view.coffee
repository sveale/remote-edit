{View, EditorView} = require 'atom'

HostView = require './view/host-view'
SftpHost = require './model/sftp-host'
FtpHost = require './model/ftp-host'

module.exports =
class MainView extends View
  previouslyFocusedElement: null
  hostView: new HostView([]);

  @content: ->
    @div class: 'remote-edit overlay from-top', =>
      @subview 'miniEditor', new EditorView(mini: true)
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'

  initialize: (serializeState) ->
    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles()
    atom.workspaceView.command "remote-edit:browse", => @browse()
    atom.workspaceView.command "remote-edit:new-host-sftp", => @newHost("sftp")
    atom.workspaceView.command "remote-edit:new-host-ftp", => @newHost("ftp")

    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

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
    ***REMOVED***2 = new SftpHost("***REMOVED***", "/home/sverre/", "sverre", 22, true, false, false, null, null, null)
    ***REMOVED***Ftp = new FtpHost("***REMOVED***", "/", "sverre", "21", "asdf")
    leetnettFtp = new FtpHost("***REMOVED***", "/", "sverre", "21", "asdf")

    @hostView.setItems([***REMOVED***, ***REMOVED***2, ***REMOVED***Ftp, leetnettFtp])
    @hostView.attach()

  newHost: (protocol) ->
    throw new Error("Not implemented!")
    @destroy()
