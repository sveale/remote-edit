{$, $$, SelectListView} = require 'atom'

RemoteFileView = require './re-file-view'
RemoteFile = require './re-file'

ssh2fs = require 'ssh2-fs'
connect = require 'ssh2-connect'
async = require 'async'
util = require 'util'
filesize = require 'file-size'
moment = require 'moment'

module.exports =
  class REFileViewFtp extends REFileView
    connection: null

    initialize: (@path, @connOpts) ->
      super(@path)
      @setupConnection(null)


    setupConnection: (callback) ->
      async.waterfall([
        (callback) =>
          @setLoading("Connecting...")
          connect(@connOpts, (err, ssh) =>
            @connection = ssh
            callback(err)
          )
        (callback) =>
          #@setItems(@getFiles(ssh))
          @setLoading("Loading...")
          @getFiles(callback)
        (items, callback) =>
          #console.debug util.inspect(items)
          @setItems(items)
      ], (err, result) =>
          return callback(err, result)
      )

    populate: (callback) ->
      async.waterfall([
          (callback) =>
            @getFiles(callback)
          (items, callback) =>
            @setItems(items)
      ], (err, result) =>
          return callback(err, result)
      )

    getFileData: (callback) ->
      ssh2fs.readFile(@connection, @path, (err, data) ->
        return callback(data)
      )

    pathIsFile: (callback) ->
      ssh2fs.stat(@connection, @path, (err, stat) ->
        callback(err, stat.isFile())
      )


    pathIsDir: (callback) ->
      ssh2fs.stat(@connection, @path, callback)

    getFiles: (callback) ->
      async.waterfall([
        (callback) =>
          @setLoading("Loading...")
          ssh2fs.readdir(@connection, @path, callback)
        (files, callback) =>
          #fungerer async.map(files, ((item, callback) => callback(null, item)), callback)
          async.mapLimit(files, @getNumberOfConcurrentSshQueriesInOneConnection(), ((item, callback) => ssh2fs.stat(@connection, @getNewPath(item), (err, stat) => callback(err, @createRemoteFileFromNameAndStat(item, stat)))), callback)
        (objects, callback) =>
          if atom.config.get 'remote-edit.showHiddenFiles'
            callback(null, objects)
          else
            async.filter(objects, @isHiddenFile, ((result) => callback(null, result)))
      ], (err, result) =>
        #console.debug util.inspect(result)
        @cancelled()
        return callback(err, (result.sort (a, b) => return if a.name.toLowerCase() >= b.name.toLowerCase() then 1 else -1))
      )

    createRemoteFileFromNameAndStat: (name, stat) ->
      remoteFile = new RemoteFile(name, stat.isFile(),
                                  stat.isDirectory(),
                                  filesize(stat.size).human(),
                                  parseInt(stat.permissions, 10).toString(8).substr(2, 4),
                                  moment(stat.mtime * 1000).format("HH:MM DD/MM/YYYY"))
      return remoteFile
