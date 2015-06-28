{$, $$, SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
LocalFile = require '../model/local-file'

Dialog = require './dialog'

fs = require 'fs'
mkdir = require 'mkdirp'
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
      @addClass('filesview')
      @connect(@host)

      @disposables = new CompositeDisposable
      @listenForEvents()

    connect: (@host, connectionOptions = {}) ->
      @path = if atom.config.get('remote-edit.rememberLastOpenDirectory') and @host.lastOpenDirectory? then @host.lastOpenDirectory else @host.directory
      async.waterfall([
        (callback) =>
          if @host.usePassword and !connectionOptions.password?
            if @host.password == "" or @host.password == '' or !@host.password?
              async.waterfall([
                (callback) ->
                  passwordDialog = new Dialog({prompt: "Enter password"})
                  passwordDialog.toggle(callback)
              ], (err, result) =>
                connectionOptions = _.extend({password: result}, connectionOptions)
                @toggle()
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
                passwordDialog.toggle(callback)
            ], (err, result) =>
              @connect(@host, {password: result})
              @toggle()
            )
          else
            @setError(err)
      )

    getFilterKey: ->
      return "name"

    destroy: ->
      @panel.destroy() if @panel?
      @disposables.dispose()

    cancelled: ->
      @hide()
      @host?.close()
      @destroy()

    toggle: ->
      if @panel?.isVisible()
        @cancel()
      else
        @show()

    show: ->
      @panel ?= atom.workspace.addModalPanel(item: this)
      @panel.show()

      @storeFocusedElement()

      @focusFilterEditor()

    hide: ->
      @panel?.hide()

    viewForItem: (item) ->
      $$ ->
        @li class: 'two-lines', =>
          if item.isFile
            @div class: 'primary-line icon icon-file-text', item.name
          else if item.isDir
            @div class: 'primary-line icon icon-file-directory', item.name
          else if item.isLink
            @div class: 'primary-line icon icon-file-symlink-file', item.name

          @div class: 'secondary-line no-icon text-subtle', "Size: #{item.size}, Mtime: #{item.lastModified}, Permissions: #{item.permissions}"



    populate: (callback) ->
      async.waterfall([
        (callback) =>
          @setLoading("Loading...")
          @host.getFilesMetadata(@path, callback)
        (items, callback) =>
          items = _.sortBy(items, 'isFile') if atom.config.get 'remote-edit.foldersOnTop'
          @setItems(items)
          callback(undefined, undefined)
      ], (err, result) =>
        @setError(err) if err?
        callback?(err, result)
      )

    populateList: ->
      super
      @setError path.resolve @path

    getNewPath: (next) ->
      if (@path[@path.length - 1] == "/")
        @path + next
      else
        @path + "/" + next

    updatePath: (next) =>
      @path = @getNewPath(next)

    makeDir: (remotePath, callback) ->
      async.waterfall([
        (callback) ->
          fs.realpath(os.tmpDir(), callback)
        (tmpDir, callback) ->
          tmpDir = tmpDir + path.sep + "remote-edit" + "-" + (new Date()).getTime().toString()
          fs.mkdir(tmpDir, ((err) ->
            if err? && err.code == 'EEXIST'
              callback(null, tmpDir)
            else
              callback(err, tmpDir)
            )
          )
        (tmpDir, callback) =>
          tmpDir = tmpDir + path.sep + remotePath
          mkdir(tmpDir, ((err) ->
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
      exists = _.filter @host.localFiles, (local) ->
        local.remoteFile.path is file.path and local.remoteFile.lastModified is file.lastModified
      unless exists.length > 0
        @setLoading("Downloading file...")
        async.waterfall([
          (callback) =>
            @makeDir(@host.username + "-" + @host.hostname + path.sep + file.path.slice(0, -file.name.length), callback)
          (savePath, callback) =>
            savePath = savePath + path.sep + file.name
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
      else
        localFile = exists[0]
        uri = "remote-edit://localFile/?localFile=#{encodeURIComponent(JSON.stringify(localFile.serialize()))}&host=#{encodeURIComponent(JSON.stringify(localFile.host.serialize()))}"
        atom.workspace.open(uri, split: 'left')
        @host.close()
        @cancel()

    openDirectory: (dir) =>
      @setLoading("Opening directory...")
      throw new Error("Not implemented yet!")

    confirmed: (item) ->
      if item.isFile
        @openFile(item)
      else if item.isDir
        @filterEditorView.setText('')
        @setItems()
        @updatePath(item.name)
        @host.lastOpenDirectory = item.path
        @host.invalidate()
        @populate()
      else if item.isLink
        if atom.config.get('remote-edit.followLinks')
          @filterEditorView.setText('')
          @setItems()
          @updatePath(item.name)
          @populate()
        else
          @openFile(item)

      else
        @setError("Selected item is neither a file, directory or link!")

    listenForEvents: ->
      @disposables.add atom.commands.add 'atom-workspace', 'filesview:open', =>
        item = @getSelectedItem()
        if item.isFile
          @openFile(item)
        else if item.isDir
          @openDirectory(item)
