{$$, SelectListView} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

async = require 'async'
Q = require 'q'
_ = require 'underscore-plus'
fs = require 'fs-plus'
moment = require 'moment'

LocalFile = require '../model/local-file'

module.exports =
  class OpenFilesView extends SelectListView
    initialize: (@ipdw) ->
      super
      @addClass('open-files-view')
      @createItemsFromIpdw()

      @disposables = new CompositeDisposable
      @disposables.add @ipdw.onDidChange => @createItemsFromIpdw()

      @listenForEvents()

    destroy: ->
      @panel.destroy() if @panel?
      @disposables.dispose()

    cancelled: ->
      @hide()
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

    getFilterKey: ->
      return "name"

    viewForItem: (localFile) ->
      $$ ->
        @li class: 'two-lines', =>
          @div class: 'primary-line icon globe', "#{localFile.host.protocol}://#{localFile.host.username}@#{localFile.host.hostname}:#{localFile.host.port}#{localFile.remoteFile.path}"
          #mtime = moment(fs.statSync(localFile.path).mtime.getTime()).format("HH:mm:ss DD/MM/YY")
          mtime = moment(fs.stat(localFile.path, (stat) => stat?.mtime?.getTime())).format("HH:mm:ss DD/MM/YY")
          @div class: 'secondary-line no-icon text-subtle', "Downloaded: #{localFile.dtime}, Mtime: #{mtime}"

    confirmed: (localFile) ->
      uri = "remote-edit://localFile/?localFile=#{encodeURIComponent(JSON.stringify(localFile.serialize()))}&host=#{encodeURIComponent(JSON.stringify(localFile.host.serialize()))}"
      atom.workspace.open(uri, split: 'left')
      @cancel()

    listenForEvents: ->
      @disposables.add atom.commands.add 'atom-workspace', 'openfilesview:delete', =>
        item = @getSelectedItem()
        if item?
          @items = _.reject(@items, ((val) -> val == item))
          item.delete()
          @setLoading()

    createItemsFromIpdw: ->
      @ipdw.getData().then((data) =>
        localFiles = []
        async.each(data.hostList, ((host, callback) ->
          async.each(host.localFiles, ((file, callback) ->
            file.host = host
            localFiles.push(file)
            ), ((err) -> console.error err if err?))
          ), ((err) -> console.error err if err?))
        @setItems(localFiles)
      )
