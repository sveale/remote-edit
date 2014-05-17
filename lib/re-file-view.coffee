{$, $$, SelectListView} = require 'atom'

fs = require 'fs'
os = require 'os'
async = require 'async'

module.exports =
  class REFileView extends SelectListView
    initialize: (@path) ->
      super
      @addClass('overlay from-top')

    getFilterKey: ->
      return "name"

    attach: ->
      atom.workspaceView.append(this)
      @focusFilterEditor()

    cancel: ->
      @hide()

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
      throw new Error("Subclass must implement a populate(callback) method")

    setupConnection: (callback) ->
      throw new Error("Subclass must implement a setupConnection(callback) method")

    getFileData: (callback) ->
      throw new Error("Subclass must implement a getFile(callback) method")

    pathIsFile: (callback)->
      throw new Error("Subclass must implement a pathIsFile(callback) method")

    pathIsDir: (callback) ->
      throw new Error("Subclass must implement a pathIsDir(callback) method")

    getFiles: (callback) ->
      throw new Error("Subclass must implement a getFiles(callback) method")

    getNumberOfConcurrentSshQueriesInOneConnection: ->
      atom.config.get 'remote-edit.numberOfConcurrentSshConnectionToOneHost'

    sortFiles: (files) ->
      if atom.config.get 'remote-edit.showHiddenFiles'
        return (files.sort (a, b) -> return if a.toLowerCase() >= b.toLowerCase() then 1 else -1)
      else
        return (files.sort (a, b) -> return if a.toLowerCase() >= b.toLowerCase() then 1 else -1).filter (file) -> !(file[0] == "." && file.length > 2)

    sortByMultiple = (a, b, keys) ->
      return r if (r = sortBy key, a, b) for key in keys
      return 0

    sortBy = (key, a, b, r) ->
      r = if r then 1 else -1
      return -1*r if a[key] > b[key]
      return +1*r if a[key] < b[key]
      return 0

    isHiddenFile: (file, callback) ->
      callback(!(file.name[0] == "." && file.name.length >2))

    getNewPath: (next) ->
      if (@path[@path.length - 1] == "/")
        @path + next
      else
        @path + "/" + next

    updatePath: (next) =>
      @path = @getNewPath(next)

    openFile: (data) =>
      savePath = os.tmpdir() + @path.split('/').pop()
      console.debug "path = #{@path}, savePath = #{savePath}"
      fs.writeFile(savePath, data, (err) =>
        throw err if err?
        atom.workspace.open(savePath)
      )

    confirmed: (item) ->
      #@updatePath(item)

      if item.isFile
        @updatePath(item.name)
        #console.debug 'file selected'
        @getFileData(@openFile)
      else if item.isDir
        @updatePath(item.name)
        @populate()
      else
        @setError("Selected item is neither a file nor a directory!")
        #throw new Error("Path is neither a file nor a directory!")
