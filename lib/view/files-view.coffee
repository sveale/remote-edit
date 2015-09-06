{$, $$, SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'
LocalFile = require '../model/local-file'

Dialog = require './dialog'

fs = require 'fs'
os = require 'os'
async = require 'async'
util = require 'util'
path = require 'path'
Q = require 'q'
_ = require 'underscore-plus'
mkdirp = require 'mkdirp'
moment = require 'moment'
upath = require 'upath'

module.exports =
  class FilesView extends SelectListView
    initialize: (@host) ->
      super
      @addClass('filesview')

      @disposables = new CompositeDisposable
      @listenForEvents()

    connect: (connectionOptions = {}) ->
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
          else if err.code is 2 and @path is @host.lastOpenDirectory
            # no such file, can occur if lastOpenDirectory is used and the dir has been removed
            @host.lastOpenDirectory = undefined
            @connect(connectionOptions)
          else if @host.usePassword and (err.code == 530 or err.level == "connection-ssh")
            async.waterfall([
              (callback) ->
                passwordDialog = new Dialog({prompt: "Enter password"})
                passwordDialog.toggle(callback)
            ], (err, result) =>
              @toggle()
              @connect({password: result})
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
      @panel?.destroy()
      @panel = atom.workspace.addModalPanel(item: this)
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
      @path = upath.normalize(@getNewPath(next))

    getDefaultSaveDirForHostAndFile: (file, callback) ->
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
          tmpDir = tmpDir + path.sep + @host.hashCode() + '_' + @host.username + "-" + @host.hostname +  file.dirName
          mkdirp(tmpDir, ((err) ->
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
      dtime = moment().format("HH:mm:ss DD/MM/YY")
      async.waterfall([
        (callback) =>
          @getDefaultSaveDirForHostAndFile(file, callback)
        (savePath, callback) =>
          savePath = savePath + path.sep + dtime.replace(/([^a-z0-9\s]+)/gi, '').replace(/([\s]+)/gi, '-') + "_" + file.name
          localFile = new LocalFile(savePath, file, dtime, @host)
          @host.getFile(localFile, callback)
      ], (err, localFile) =>
        if err?
          @setError(err)
          console.error err
        else
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
        @filterEditorView.setText('')
        @setItems()
        @updatePath(item.name)
        @host.lastOpenDirectory = upath.normalize(item.path)
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
