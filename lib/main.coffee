MainView = require './main-view'
util = require 'util'
_ = require 'underscore-plus'

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
    console.debug util.inspect(state)
    @view =
      if state? and _.size(state) > 0
        atom.deserializers.deserialize(state)
      else
        new MainView()

  deactivate: ->
    @view?.destroy()

  serialize: ->
    @view.serialize()
