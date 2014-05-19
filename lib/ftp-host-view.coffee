HostView = require './host-view'

module.exports =
  class FtpHostView extends HostView
    initialize: (@listofItems) ->
      super

    confirmed: (item) ->
      if (item == 'Add new')
        @addNewItem()
      else
        throw new Error("Not implemented!")
