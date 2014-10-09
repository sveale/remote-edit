path = require 'path'
resourcePath = atom.config.resourcePath
Editor = require path.resolve resourcePath, 'src', 'text-editor'
DisplayBuffer = require path.resolve resourcePath, 'src', 'display-buffer'
Serializable = require 'serializable'

# Defer requiring
Host = null
FtpHost = null
SftpHost = null
LocalFile = null

module.exports =
  class RemoteEditEditor extends Editor
    Serializable.includeInto(this)
    atom.deserializers.add(this)

    Editor.registerDeserializer(RemoteEditEditor)

    constructor: ({@softTabs, initialLine, initialColumn, tabLength, softWrap, @displayBuffer, buffer, registerEditor, suppressCursorCreation, @mini, @host, @localFile}) ->
      super({@softTabs, initialLine, initialColumn, tabLength, softWrap, @displayBuffer, buffer, registerEditor, suppressCursorCreation, @mini})

    getIconName: ->
      "globe"

    getTitle: ->
      if @localFile?
        @localFile.name
      else if sessionPath = @getPath()
        path.basename(sessionPath)
      else
        "undefined"

    getLongTitle: ->
      Host ?= require './host'
      FtpHost ?= require './ftp-host'
      SftpHost ?= require './sftp-host'

      fileName = @getTitle()
      if @host instanceof SftpHost and @host? and @localFile?
        directory = "sftp://#{@host.username}@#{@host.hostname}:#{@host.port}#{@localFile.remoteFile.path}"
      else if @host instanceof FtpHost and @host? and @localFile?
        directory = "ftp://#{@host.username}@#{@host.hostname}:#{@host.port}#{@localFile.remoteFile.path}"
      else
        directory = atom.project.relativize(path.dirname(sessionPath))
        directory = if directory.length > 0 then directory else path.basename(path.dirname(sessionPath))

      "#{fileName} - #{directory}"

    save: ->
      @buffer.save()
      @emit 'saved'

    saveAs: (filePath) ->
      @buffer.saveAs(filePath)
      @localFile.path = filePath

    getViewClass: ->
      require '../view/remote-edit-editor-view'

    serializeParams: ->
      id: @id
      softTabs: @softTabs
      scrollTop: @scrollTop
      scrollLeft: @scrollLeft
      displayBuffer: @displayBuffer.serialize()
      title: @title
      localFile: @localFile?.serialize()
      host: @host?.serialize()

    deserializeParams: (params) ->
      params.displayBuffer = DisplayBuffer.deserialize(params.displayBuffer)
      params.registerEditor = true
      if params.localFile?
        LocalFile = require '../model/local-file'
        params.localFile = LocalFile.deserialize(params.localFile)
      if params.host?
        Host = require '../model/host'
        FtpHost = require '../model/ftp-host'
        SftpHost = require '../model/sftp-host'
        params.host = Host.deserialize(params.host)
      params
