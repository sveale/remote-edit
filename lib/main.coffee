MainView = require './main-view'

module.exports =
  mainView: null
  configDefaults:
    showHiddenFiles: false,
    savePasswordInClearText: true,
    numberOfConcurrentSshQueriesInOneConnection: 5,
    sshUseUserAgent: true,
    sshUsePrivateKey: false,
    sshPrivateKey: "~/.ssh/id_rsa",
    sshPrivateKeyPassphrase: undefined


  activate: (state) ->
    @mainView = new MainView(state.reViewState)

  deactivate: ->
    @mainView?.destroy()

  serialise: ->
    mainViewState: @mainView.serialize()
