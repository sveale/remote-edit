{$, $$, WorkspaceView} = require 'atom'
fs = require 'fs-plus'
temp = require('temp').track()
path = require 'path'
Q = require 'q'

InterProcessData = require '../lib/model/inter-process-data'
Host = require '../lib/model/host'
FtpHost = require '../lib/model/ftp-host'
SftpHost = require '../lib/model/sftp-host'

describe "HostsView", ->
  [hostsView] = []

  beforeEach ->
    tmpDirPath = fs.realpathSync(temp.mkdirSync('atom-remote-edit'))
    tmpFilePath = "#{tmpDirPath}/remoteEdit.json"

    ftpHostNoPassword = new FtpHost("ftpHostNoPassword", "/", "username", "21", [], true)
    ftpHostWithPassword = new FtpHost("ftpHostNoPassword", "/", "username", "21", [], true, "password")
    sftpHostAgent = new SftpHost("sftpHostAgent", "/", "username", "22", [], false, true, false, undefined, undefined, undefined)
    sftpHostPkey = new SftpHost("sftpHostPkey", "/", "username", "22", [], false, false, true, undefined, "passphrase", undefined)
    sftpHostPassword = new SftpHost("sftpHostPassword", "/", "username", "22", [], true, false, false, "password", undefined, undefined)

    ipd = new InterProcessData([ftpHostNoPassword, ftpHostWithPassword, sftpHostAgent, sftpHostPkey, sftpHostPassword])

    fs.writeFileSync(tmpFilePath, JSON.stringify(ipd.serialize()))

    ipd.destroy()

    atom.workspaceView = new WorkspaceView
    activationPromise = null
    atom.config.set 'remote-edit.defaultSerializePath', "#{tmpFilePath}"

    runs ->
      activationPromise = atom.packages.activatePackage("remote-edit")
      atom.workspaceView.attachToDom().focus()
      atom.workspaceView.trigger('remote-edit:browse')

    waitsForPromise ->
      activationPromise

    listGroup = null
    runs ->
      hostsView = atom.workspaceView.find(".hosts-view").view()
      listGroup = hostsView.find(".list-group")

    waitsFor ->
      listGroup.children().length > 1

  afterEach ->
    temp.cleanup()
    atom.workspaceView.remove()

  describe "remote-edit:browse", ->
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
