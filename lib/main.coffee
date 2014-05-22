MainView = require './main-view'

module.exports =
  configDefaults:
    showHiddenFiles: false,
    savePasswordInClearText: true,
    numberOfConcurrentSshQueriesInOneConnection: 5,
    sshUseUserAgent: true,
    sshUsePrivateKey: false,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    sshPrivateKeyPassphrase: ""


  activate: (state) ->
    @view =
      if state
        atom.deserializers.deserialize(state)
      else
        new MainView()

  deactivate: ->
    @view?.destroy()

  serialize: ->
    @view.serialize()
