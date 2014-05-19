{View} = require 'atom'

HostView = require './view/host-view'
SftpHost = require './model/sftp-host'
FtpHost = require './model/ftp-host'

module.exports =
class MainView extends View
  previouslyFocusedElement: null
  mode: null
  sftpHostView: null
  ftpHostView: null

  @content: ->
    @div class: 'remote-edit overlay from-top', =>

  initialize: (serializeState) ->
    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles()
    atom.workspaceView.command "remote-edit:browse", => @browse()

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
    @hostView = new HostView([***REMOVED***, ***REMOVED***2, ***REMOVED***Ftp, leetnettFtp])
    @hostView.attach()
