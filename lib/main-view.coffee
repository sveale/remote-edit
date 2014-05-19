{$, BufferedProcess, EditorView, View} = require 'atom'

HostView = require './view/host-view'
SftpHost = require './model/sftp-host'
FtpHost = require './model/ftp-host'

module.exports =
class MainView extends View
  previouslyFocusedElement: null
  hostView: new HostView([]);

  @content: ->
    @div class: 'remote-edit overlay from-top', =>
      @div class: 'error', outlet: 'error'
      @div class: 'message', outlet: 'message'
      @label 'Hostname'
      @subview 'hostName', new EditorView(mini: true)
      @subview 'username', new EditorView(mini: true)
      @subview 'port', new EditorView(mini: true)
      @subview 'directory', new EditorView(mini: true)



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
    @previouslyFocusedElement = $(':focus')
    @message.text("Enter data")
    atom.workspaceView.append(this)
    if @protocol == 'sftp'
      console.debug 'sftp'
    else if @protocol == 'ftp'
      console.debug 'ftp'
    else
      console.debug 'asdf'

    @hostName.focus()

  confirm: ->
    @detach()
    @browse()
