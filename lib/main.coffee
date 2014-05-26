MainView = require './main-view'
util = require 'util'
_ = require 'underscore-plus'

module.exports =
  configDefaults:
    showHiddenFiles: false,
    numberOfConcurrentSshQueriesInOneConnection: 5,
    sshPrivateKeyPath: "~/.ssh/id_rsa",
    defaultSerializePath: "~/.atom/remoteEdit.json"

  activate: (state) ->
    @view = new MainView()

  deactivate: ->
    @view?.destroy()

  serialize: ->
    @view?.serialize()
