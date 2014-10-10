{$, $$, SelectListView} = require 'atom'
LocalFile = require '../model/local-file'

Dialog = require './dialog'

fs = require 'fs'
os = require 'os'
async = require 'async'
util = require 'util'
path = require 'path'
Q = require 'q'
_ = require 'underscore-plus'

module.exports =
  class FilesView extends SelectListView
    initialize: (@host) ->
      super
      @addClass('overlay from-top filesview')
      @connect(@host)
      @listenForEvents()

    connect: (@host, connectionOptions = {}) ->
      @path = @host.directory
      async.waterfall([
        (callback) =>
          if @host.usePassword and !connectionOptions.password?
            if @host.password == "" or @host.password == '' or !@host.password?
              async.waterfall([
                (callback) ->
                  passwordDialog = new Dialog({prompt: "Enter password"})
                  passwordDialog.attach(callback)
              ], (err, result) =>
                connectionOptions = _.extend({password: result}, connectionOptions)
                @attach()
                callback(null)
              )
            else
              callback(null)
          else
            callback(null)
        (callback) =>
          if !@host.isConnected()
            @setLoading("Connecting...")
            @host.connect(callback, connectionOptions)
          else
            callback(null)
        (callback) =>
          @populate(callback)
      ], (err, result) =>
        if err?
          console.error err
          if err.code == 450 or err.type == "PERMISSION_DENIED"
            @setError("You do not have read permission to what you've specified as the default directory! See the console for more info.")
          else if @host.usePassword and (err.code == 530 or err.level == "connection-ssh")
            async.waterfall([
              (callback) ->
                passwordDialog = new Dialog({prompt: "Enter password"})
                passwordDialog.attach(callback)
            ], (err, result) =>
              @connect(@host, {password: result})
              @attach()
            )
          else
            @setError(err)
      )

    getFilterKey: ->
      return "name"

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    viewForItem: (item) ->
      $$ ->
        @li class: 'two-lines', =>
          if item.isFile
            @div class: 'primary-line icon icon-file-text', item.name
            @div class: 'secondary-line no-icon text-subtle', "Size: #{item.size}, Mtime: #{item.lastModified}, Permissions: #{item.permissions}"
          else if item.isDir
            @div class: 'primary-line icon icon-file-directory', item.name
            @div class: 'secondary-line no-icon text-subtle', "Size: #{item.size}, Mtime: #{item.lastModified}, Permissions: #{item.permissions}"
          else

    populate: (callback) ->
      async.waterfall([
        (callback) =>
          @setLoading("Loading...")
          @host.getFilesMetadata(@path, callback)
        (items, callback) =>
          @setItems(items)
          @cancelled()
      ], (err, result) =>
        @setError(err) if err?
        callback?(err, result)
      )

    getNewPath: (next) ->
      if (@path[@path.length - 1] == "/")
        @path + next
      else
        @path + "/" + next

    updatePath: (next) =>
      @path = @getNewPath(next)

    getDefaultSaveDirForHost: (callback) ->
      async.waterfall([
        (callback) ->
          fs.realpath(os.tmpDir(), callback)
        (tmpDir, callback) ->
          tmpDir = tmpDir + path.sep + "remote-edit"
          fs.mkdir(tmpDir, ((err) ->
            if err? && err.code == 'EEXIST'
              callback(null, tmpDir)
            else
              callback(err, tmpDir)
            )
          )
        (tmpDir, callback) =>
          tmpDir = tmpDir + path.sep + @host.hashCode()
          fs.mkdir(tmpDir, ((err) ->
            if err? && err.code == 'EEXIST'
              callback(null, tmpDir)
            else
              callback(err, tmpDir)
            )
          )
      ], (err, savePath) ->
        callback(err, savePath)
      )

    openFile: (file) =>
      @setLoading("Downloading file...")
      async.waterfall([
        (callback) =>
          @getDefaultSaveDirForHost(callback)
        (savePath, callback) =>
          savePath = savePath + path.sep + (new Date()).getTime().toString() + "-" + file.name
          @host.getFileData(file, ((err, data) -> callback(err, data, savePath)))
        (data, savePath, callback) ->
          fs.writeFile(savePath, data, (err) -> callback(err, savePath))
      ], (err, savePath) =>
        if err?
          @setError(err)
          console.error err
        else
          localFile = new LocalFile(savePath, file, @host)
          @host.addLocalFile(localFile)
          uri = "remote-edit://localFile/?localFile=#{encodeURIComponent(JSON.stringify(localFile.serialize()))}&host=#{encodeURIComponent(JSON.stringify(localFile.host.serialize()))}"
          atom.workspace.open(uri, split: 'left')

          @host.close()
          @cancel()
      )

    openDirectory: (dir) =>
      @setLoading("Opening directory...")
      throw new Error("Not implemented yet!")

    confirmed: (item) ->
      if item.isFile
        @openFile(item)
      else if item.isDir
        @setItems()
        @updatePath(item.name)
        @populate()
      else
        @setError("Selected item is neither a file nor a directory!")
        #throw new Error("Path is neither a file nor a directory!")

    listenForEvents: ->
      @command 'filesview:open', =>
        item = @getSelectedItem()
        if item.isFile
          @openFile(item)
        else if item.isDir
          @openDirectory(item)

    cancel: ->
      super

      @host?.close()
