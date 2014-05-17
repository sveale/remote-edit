{WorkspaceView} = require 'atom'
RemoteEdit = require '../lib/remote-edit'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "RemoteEdit", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('remote-edit')

  describe "when the remote-edit:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.remote-edit')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'remote-edit:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.remote-edit')).toExist()
        atom.workspaceView.trigger 'remote-edit:toggle'
        expect(atom.workspaceView.find('.remote-edit')).not.toExist()
