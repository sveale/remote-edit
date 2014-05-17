{View} = require 'atom'
#SftpHostView = require './sftp-host-view'
#FtpHostView = require './ftp-host-view'
RemoteEditHostView = require './remote-edit-host-view'


module.exports =
class RemoteEditView extends View
  previouslyFocusedElement: null
  mode: null

  @content: ->
    @div class: 'remote-edit overlay from-top', =>
      @div "The RemoteEdit package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "remote-edit:show-open-files", => @showOpenFiles
    atom.workspaceView.command "remote-edit:browse-sftp", => @attach('sftp')
    atom.workspaceView.command "remote-edit:browse-ftp", => @attach('ftp')

    @on 'core:confirm', => @confirm()
    @on 'core:cancel', => @detach()

    #@sftpHostView = new SftpHostView(serializeState)
    #@ftpHostView = new FtpHostView(serializeState)

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
      #@sftpHostView.attach()
      remoteEditHostView = new RemoteEditHostView(['***REMOVED***', '***REMOVED***'])
      remoteEditHostView.attach()
    else if @mode == 'ftp'
      #@ftpHostView.attach()
    else
      throw new Error("#{mode} is not supported!")
