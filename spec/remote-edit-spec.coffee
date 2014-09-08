{$, $$, WorkspaceView} = require 'atom'
Q = require 'q'

CreateFixtures = require './create-fixtures'

describe "remote-edit:", ->
  beforeEach ->
    fixture = new CreateFixtures()

    atom.workspaceView = new WorkspaceView
    activationPromise = null
    atom.config.set 'remote-edit.defaultSerializePath', "#{fixture.getSerializePath()}"

    runs ->
      activationPromise = atom.packages.activatePackage("remote-edit")
      atom.workspaceView.attachToDom().focus()

    waitsForPromise ->
      activationPromise

  afterEach ->
    atom.workspaceView.remove()

  describe "show-open-files", ->
    [openFilesView, listGroup] = []

    beforeEach ->
      runs ->
        atom.workspaceView.trigger('remote-edit:show-open-files')
        openFilesView = atom.workspaceView.find(".open-files-view")
        listGroup = openFilesView.find(".list-group")

      waitsFor ->
        listGroup.children().length > 1

    it "displays correct number of open files", ->
      expect(openFilesView).toExist()
      expect(listGroup.find(".local-file").length).toBe 2

  describe "browse", ->
    [hostsView, listGroup] = []

    beforeEach ->
      runs ->
        atom.workspaceView.trigger('remote-edit:browse')
        hostsView = atom.workspaceView.find(".hosts-view").view()
        listGroup = hostsView.find(".list-group")

      waitsFor ->
        listGroup.children().length > 1

    it "displays correct auth schemes", ->
      expect(hostsView).toExist()
      expect(hostsView.find(".two-lines").text()).toContain('agent')
      expect(hostsView.find(".two-lines").text()).toContain('password')
      expect(hostsView.find(".two-lines").text()).toContain('key')

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

  describe "new-host-sftp", ->

  describe "new-host-ftp", ->
