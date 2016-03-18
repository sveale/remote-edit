{$, $$, View} = require 'atom-space-pen-views'
{CompositeDisposable, Emitter} = require 'atom'
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
  class FilesView extends View

    @content: ->
      @div class: 'remote-edit-tree-view remote-edit-resizer tool-panel', 'data-show-on-right-side': false, =>
        @div class: 'remote-edit-scroller order--center', =>
          @div class: 'remote-edit-info focusable-panel', tabindex: -1, click: 'clickInfo', =>
            @p class: 'remote-edit-server', =>
              @span class: 'remote-edit-server-type inline-block', 'FTP:'
              @span class: 'remote-edit-server-alias inline-block highlight', outlet: 'server_alias', 'unknown'
            @p class: 'remote-edit-folder text-bold', =>
              @span 'Folder: '
              @span outlet: 'server_folder', 'unknown'

          @div class: 'remote-edit-scroller', outlet: 'scroller', =>
            @ol class: 'list-tree full-menu focusable-panel', tabindex: -1, outlet: 'list'
          @div class: 'remote-edit-message', outlet: 'message'
        @div class: 'remote-edit-resize-handle', outlet: 'resizeHandle'

    initialize: (@host) ->
      @emitter = new Emitter
      @disposables = new CompositeDisposable
      @listenForEvents()

    connect: (connectionOptions = {}, connect_path = false) ->
      dir = upath.normalize(if connect_path then connect_path else if atom.config.get('remote-edit.rememberLastOpenDirectory') and @host.lastOpenDirectory? then @host.lastOpenDirectory else @host.directory)
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
            @setMessage("Connecting...")
            @host.connect(callback, connectionOptions)
          else
            callback(null)
        (callback) =>
          @populate(dir, callback)
      ], (err, result) =>
        if err?
          console.error err
          @list.empty()
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
        @hide()
      else
        @show()

    show: ->
      @panel ?= atom.workspace.addLeftPanel(item: this, visible: true)
      @panel?.show()

    hide: ->
      @panel?.hide()

    viewForItem: (item) ->
      icon = switch
        when item.isDir then 'icon-file-directory'
        when item.isLink then 'icon-file-symlink-file'
        else 'icon-file-text'
      $$ ->
        @li class: 'list-item list-selectable-item two-lines', =>
          @span class: 'primary-line icon '+ icon, 'data-name' : item.name, title : item.name, item.name
          if item.name != '..'
            @span class: 'text-subtle text-smaller', "S: #{item.size}, M: #{item.lastModified}, P: #{item.permissions}"

    populate: (dir, callback) ->
      async.waterfall([
        (callback) =>
          @host.getFilesMetadata(dir, callback)
        (items, callback) =>
          items = _.sortBy(items, 'isFile') if atom.config.get 'remote-edit.foldersOnTop'
          @setItems(items)
          callback(undefined, undefined)
      ], (err, result) =>
        @updatePath(dir)
        @populateInfo()
        @setError(err) if err?
        callback?(err, result)
      )

    populateList: ->
      super
      @setError path.resolve @path

    populateInfo: ->
      @server_alias.html(if @host.alias then @host.alias else @host.hostname)
      @server_folder.html(@path)

    getNewPath: (next) ->
      if (@path[@path.length - 1] == "/")
        @path + next
      else
        @path + "/" + next

    updatePath: (next) =>
      @path = upath.normalize(next)
      @host.lastOpenDirectory = @path
      @server_folder.html(@path)

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
      dtime = moment().format("HH:mm:ss DD/MM/YY")
      async.waterfall([
        (callback) =>
          @getDefaultSaveDirForHostAndFile(file, callback)
        (savePath, callback) =>
          savePath = savePath + path.sep + dtime.replace(/([^a-z0-9\s]+)/gi, '').replace(/([\s]+)/gi, '-') + "_" + file.name
          localFile = new LocalFile(savePath, file, dtime, @host)
          @host.getFile(localFile, callback)
          uri = path.normalize(savePath)
          filePane = atom.workspace.paneForURI(uri)
          if filePane
            filePaneItem = filePane.itemForURI(uri)
            filePane.activateItem(filePaneItem)
            confirmResult = atom.confirm
              message: 'Reopen this file?'
              detailedMessage: 'Unsaved data will be lost.'
              buttons: ['Yes','No']
            # confirmResult: Yes = 0, No = 1, Close button = 1
            if confirmResult
              callback(null, null)
            else
              filePaneItem.destroy()

          if !filePane or !confirmResult
            localFile = new LocalFile(savePath, file, dtime, @host)
            @host.getFile(localFile, callback)
      ], (err, localFile) =>
        @deselect()
        if err?
          @setError(err)
          console.error err
        else if localFile
          @host.addLocalFile(localFile)
          uri = "remote-edit://localFile/?localFile=#{encodeURIComponent(JSON.stringify(localFile.serialize()))}&host=#{encodeURIComponent(JSON.stringify(localFile.host.serialize()))}"
          atom.workspace.open(uri, split: 'left')
      )

    openDirectory: (dir) =>
      dir = upath.normalize(dir)
      async.waterfall([
        (callback) =>
          if !@host.isConnected()
            @connect({}, dir)
          callback(null)
        (callback) =>
          @host.invalidate()
          @populate(dir)
      ], (err, savePath) ->
        callback(err, savePath)
      )

    confirmed: (item) ->
      async.waterfall([
        (callback) =>
          if !@host.isConnected()
            dir = if item.isFile then item.dirName else item.path
            @connect({}, dir)
          callback(null)
        (callback) =>
          if item.isFile
            @openFile(item)
          else if item.isDir
            @host.invalidate()
            @populate(item.path)
          else if item.isLink
            if atom.config.get('remote-edit.followLinks')
              @populate(item.path)
            else
              @openFile(item)
      ], (err, savePath) ->
        callback(err, savePath)
      )
    clickInfo: (event, element) ->
      #console.log event

    resizeStarted: =>
      $(document).on('mousemove', @resizeTreeView)
      $(document).on('mouseup', @resizeStopped)

    resizeStopped: =>
      $(document).off('mousemove', @resizeTreeView)
      $(document).off('mouseup', @resizeStopped)

    resizeTreeView: ({pageX, which}) =>
      return @resizeStopped() unless which is 1
      width = pageX - @offset().left
      @width(width)

    resizeToFitContent: ->
      @width(1) # Shrink to measure the minimum width of list
      @width(@list.outerWidth())

    listenForEvents: ->
      @list.on 'mousedown', 'li', (e) =>
        if $(e.target).closest('li').hasClass('selected')
          false
        @deselect()
        @selectedItem = $(e.target).closest('li').addClass('selected').data('select-list-item')
        if e.which == 1
          @confirmed(@selectedItem)
          e.preventDefault()
          false
        else if e.which == 3
          false

      @on 'dblclick', '.remote-edit-resize-handle', =>
        @resizeToFitContent()

      @on 'mousedown', '.remote-edit-resize-handle', (e) => @resizeStarted(e)

      @disposables.add atom.commands.add 'atom-workspace', 'filesview:open', =>
        item = @getSelectedItem()
        if item.isFile
          @openFile(item)
        else if item.isDir
          @openDirectory(item)

      @disposables.add atom.commands.add 'atom-workspace', 'filesview:previous-folder', =>
        if @path.length > 1
          @openDirectory(@path + path.sep + '..')

    setItems: (@items=[]) ->
      @message.hide()
      return unless @items?

      @list.empty()
      if @items.length
        for item in items
          itemView = $(@viewForItem(item))
          itemView.data('select-list-item', item)
          @list.append(itemView)
      else
        @setMessage('No matches found')

    reloadFolder: () =>
      @openDirectory(@path)

    createFolder: () =>
      if typeof @host.createFolder == 'function'
        async.waterfall([
          (callback) ->
            nameDialog = new Dialog({prompt: "Enter the name for new folder."})
            nameDialog.toggle(callback)
          (foldername, callback) =>
            @host.createFolder(@path + "/" + foldername, callback)
        ], (err, result) =>
          @openDirectory(@path)
        )
      else
        throw new Error("Not implemented yet!")

    createFile: () =>
      if typeof @host.createFile == 'function'
        async.waterfall([
          (callback) ->
            nameDialog = new Dialog({prompt: "Enter the name for new file."})
            nameDialog.toggle(callback)
          (filename, callback) =>
            @host.createFile(@path + "/" + filename, callback)
        ], (err, result) =>
          @openDirectory(@path)
        )
      else
        throw new Error("Not implemented yet!")

    renameFolderFile: () =>
      if typeof @host.renameFolderFile == 'function'
        if @selectedItem and @selectedItem.name and @selectedItem.name != '.'
          async.waterfall([
            (callback) =>
              nameDialog = new Dialog({prompt: """Enter the new name for #{if @selectedItem.isDir then 'folder' else if @selectedItem.isFile then 'file' else 'link'} "#{@selectedItem.name}"."""})
              nameDialog.miniEditor.setText(@selectedItem.name)
              nameDialog.toggle(callback)
            (newname, callback) =>
              @deselect()
              @host.renameFolderFile(@path, @selectedItem.name, newname, @selectedItem.isDir, callback)
          ], (err, result) =>
            @openDirectory(@path)
          )
      else
        throw new Error("Not implemented yet!")

    deleteFolderFile: () =>
      if typeof @host.deleteFolderFile == 'function'
        if @selectedItem and @selectedItem.name and @selectedItem.name != '.'
          atom.confirm
            message: "Are you sure you want to delete #{if @selectedItem.isDir then'folder' else if @selectedItem.isFile then 'file' else 'link'}?"
            detailedMessage: "You are deleting: #{@selectedItem.name}"
            buttons:
               'Yes': =>
                 @host.deleteFolderFile(@path + "/" + @selectedItem.name, @selectedItem.isDir, () =>
                   @openDirectory(@path)
                 )
               'No': =>
                @deselect()

          @selectedItem = false
      else
        throw new Error("Not implemented yet!")

    deselect: () ->
        @list.find('li.selected').removeClass('selected');

    setError: (message='') ->
      @emitter.emit 'info', {message: message, type: 'error'}

    setMessage: (message='') ->
      @message.empty().show().append("<ul class='background-message centered'><li>#{message}</li></ul>")
