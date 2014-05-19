{View} = require 'atom'

SftpHostView = require './sftp-host-view'
FtpHostView = require './ftp-host-view'


module.exports =
class MainView extends View
  previouslyFocusedElement: null
  mode: null
  sftpHostView: null
  ftpHostView: null

  @content: ->
    @div class: 'remote-edit overlay from-top', =>

  initialize: (serializeState) ->
    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles
    atom.workspaceView.command "remote-edit:browse-sftp", => @attach('sftp')
    atom.workspaceView.command "remote-edit:browse-ftp", => @attach('ftp')

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

  attach: (@mode) ->
    if @mode == 'sftp'
      @sftpHostView = new SftpHostView(['sverre@***REMOVED***:22', 'sverre@***REMOVED***:22'])
      @sftpHostView.attach()
    else if @mode == 'ftp'
      @ftpHostView = new FtpHostView(["sverre@***REMOVED***:21", "sverre@***REMOVED***:21"])
      @ftpHostView.attach()
    else
      throw new Error("#{mode} is not supported!")
