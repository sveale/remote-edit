{$, $$, SelectListView, EditorView} = require 'atom'
LocalFile = require '../model/local-file'
FileEditorView = require './file-editor-view'
Dialog = require './dialog'

fs = require 'fs'
os = require 'os'
async = require 'async'
util = require 'util'
path = require 'path'
Q = require 'q'

module.exports =
  class FilesView extends SelectListView
    initialize: (@host) ->
      super
      @addClass('overlay from-top')
      @connect(@host)

    connect: (@host, connectionOptions = {}) ->
      @path = @host.directory
      async.waterfall([
        (callback) =>
          @setLoading("Connecting...")
          @host.connect(callback, connectionOptions)
        (callback) =>
          @populate(callback)
        ], (err, result) =>
          if err? and @host.usePassword
            console.error err if err?
            @setError(err) if err?
            async.waterfall([
              (callback) =>
                passwordDialog = new Dialog({prompt: "Enter password"})
                passwordDialog.attach(callback)
              ], (err, result) =>
                @connect(@host, {password: result})
                @attach()
              )
        )

    getFilterKey: ->
      return "name"

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    viewForItem: (item) ->
      #console.debug 'viewforitem'
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
          @host.getFilesMetadata(path.normalize(@path), callback)
        (items, callback) =>
          @setItems(items)
          @cancelled()
        ], (err, result) =>
          @setError(err) if err?
          return callback(err, result)
        )

    getNewPath: (next) ->
      if (@path[@path.length - 1] == "/")
        path.normalize(@path + next)
      else
        path.normalize(@path + "/" + next)

    updatePath: (next) =>
      @path = @getNewPath(next)

    getDefaultSaveDirForHost: (callback) ->
      async.waterfall([
        (callback) ->
          fs.realpath(os.tmpDir(), callback)
        (path, callback) ->
          path = path + "/remote-edit"
          fs.mkdir(path, ((err) ->
            if err? && err.code == 'EEXIST'
              callback(null, path)
            else
              callback(err, path)
            )
          )
        (path, callback) =>
          path = path + "/" + @host.hashCode()
          fs.mkdir(path, ((err) ->
            if err? && err.code == 'EEXIST'
              callback(null, path)
            else
              callback(err, path)
            )
          )
        ], (err, savePath) ->
          callback(err, savePath)
        )

    openFile: (file) =>
      async.waterfall([
        (callback) =>
          @getDefaultSaveDirForHost(callback)
        (savePath, callback) =>
          savePath = savePath + "/" + (new Date()).getTime().toString() + "-" + file.name
          @host.getFileData(file, ((err, data) -> callback(err, data, savePath)))
        (data, savePath, callback) =>
          fs.writeFile(savePath, data, (err) -> callback(err, savePath))
      ], (err, savePath) =>
        if err?
          @setError(err)
          console.debug err
        else
          localFile = new LocalFile(savePath, file, @host)
          @host.addLocalFile(localFile)
          uri = "remote-edit://editor/#{localFile.path}"
          atom.workspace.open(uri, split: 'left')
          @host.close()
          @cancel()
      )

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
