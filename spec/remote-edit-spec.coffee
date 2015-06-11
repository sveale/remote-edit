{$, $$} = require 'atom-space-pen-views'
Q = require 'q'

CreateFixtures = require './create-fixtures'

describe "remote-edit:", ->
  [workspaceElement, editorElement] = []

  beforeEach ->
    fixture = new CreateFixtures()

    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = null
    atom.config.set 'remote-edit.defaultSerializePath', "#{fixture.getSerializePath()}"

    waitsForPromise ->
      atom.workspace.open()

    runs ->
      editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
      activationPromise = atom.packages.activatePackage("remote-edit")
      jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      activationPromise

  # afterEach ->
  #

  # describe "when show-open-files is triggered", ->
  #   it "shows two open files", ->
  #
  #

  # describe "browse", ->

    # it "correctly displays FTP hosts", ->
    #   expect

    #
    # it "can display SFTP hosts", ->
    #
    # it "can display both FTP and SFTP hosts", ->
    #
    # it "can delete hosts", ->
    #
    # it "can edit hosts", ->
    #
    # it "can open FTP hosts", ->
    #
    # it "can open SFTP hosts", ->
    #
    # it "display correct number of open files", ->

  # describe "new-host-sftp", ->
  #
  # describe "new-host-ftp", ->
