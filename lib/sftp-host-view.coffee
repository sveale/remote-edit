HostView = require './host-view'
SftpFilesView = require './sftp-files-view'
fs = require 'fs'

module.exports =
  class SftpHostView extends HostView
    initialize: (@listofItems) ->
      super

    confirmed: (item) ->
      if (item == 'Add new')
        @addNewItem()
      else
        #connOpts = {host: '***REMOVED***', username: 'sverre', privateKeyPath: "/Users/sveale/.ssh/id_rsa", passphrase: "***REMOVED***"}

        sftpFilesView = new SftpFilesView('/', @getConnOpts())
        sftpFilesView.attach()

    getPrivateKey: ->
      return fs.readFileSync((atom.config.get 'remote-edit.numberOfConcurrentSshConnectionToOneHost'), 'ascii', (err, data) ->
        return data.trim()
      )

    getConnOpts: ->
      if atom.config.get 'remote-edit.sshUseUserAgent'
        return {host: '***REMOVED***', username: 'sverre', agent: process.env['SSH_AUTH_SOCK']}
      else if atom.config.get 'remote-edit.sshUsePrivateKey'
        return {host: '***REMOVED***', username: 'sverre', privateKey: @getPrivateKey(), passphrase: "asdf"}
      else
        return undefined
