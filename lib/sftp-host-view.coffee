HostView = require './host-view'
SftpFilesView = require './sftp-files-view'
fs = require 'fs'
us = require 'underscore'

module.exports =
  class SftpHostView extends HostView
    initialize: (@listofItems) ->
      super

    confirmed: (item) ->
      if (item == 'Add new')
        @addNewItem()
      else
        #connOpts = {host: '***REMOVED***', username: 'sverre', privateKeyPath: "/Users/sveale/.ssh/id_rsa", passphrase: "***REMOVED***"}

        sftpFilesView = new SftpFilesView('/', @getConnOpts(@getValuesFromItem(item)))
        sftpFilesView.attach()

    getPrivateKey: ->
      return fs.readFileSync((atom.config.get 'remote-edit.numberOfConcurrentSshConnectionToOneHost'), 'ascii', (err, data) ->
        return data.trim()
      )

    getPrivateKeyPassphrase: ->
      return (atom.config.get 'remote-edit.sshPrivateKeyPassphrase')

    getConnOpts: (item) ->
      json = {}

      if item[0]?
        us.extend(json, {username: item[0]})
      else
        us.extend(json, {username: process.env['USER']})

      if item[1]?
        us.extend(json, {host: item[1]})
      else
        throw new Error("Host needs to be set!")

      if item[2]?
        us.extend(json, {port: item[2]})
      else
        us.extend(json, {port: 22})

      if atom.config.get 'remote-edit.sshUseUserAgent'
        us.extend(json, {agent: process.env['SSH_AUTH_SOCK']})
      else if atom.config.get 'remote-edit.sshUsePrivateKey'
        us.extend(json, {privateKey: @getPrivateKey(), passphrase: @getPrivateKeyPassphrase})
      else
        # Query for password?

      json
