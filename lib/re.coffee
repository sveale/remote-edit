RemoteEditView = require './remote-edit-view'

module.exports =
  remoteEditView: null
  configDefaults:
    showHiddenFiles: false,
    savePasswordInClearText: true,
    numberOfConcurrentSshQueriesInOneConnection: 5


  activate: (state) ->
    @remoteEditView = new RemoteEditView(state.remoteEditViewState)

  deactivate: ->
    @remoteEditView?.destroy()

  serialise: ->
    remoteEditViewState: @remoteEditView.serialize()
