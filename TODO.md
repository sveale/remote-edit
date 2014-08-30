* ~~Implement remote sync~~
  * ~~write metadata about remote file and host~~
  * ~~implement abstract write method in ftp/sftp~~
  * ~~listening for "save" events from files~~
  * ~~send open remote files to main-view and persist~~
* ~~review settings~~
* ~~figure out how to grab latest version of ftp from github with fixes~~
* ~~display open files~~
* ~~add status updates when files are updated~~
* ~~look at how promises can be utilized in inter-process-data.coffee and other parts of the package~~
* ~~**add password prompt if specified auth scheme and no password is present**~~
* when remote files are displayed show where they're from
  * ~~mark open remote files as remote~~
  * modify status-bar to show origin
* ~~keyboard shortcuts for deleting hosts/files~~ (ctrl-d)
  * ~~showing keyboard shortcut in list~~ not viable to display shortcuts for commands inside of lists
* ~~optional prompt when remote files are saved~~
* ~~remove subscription from host.coffee and place the logic in file-editor-view.coffee~~
* ~~persisted file-editor-view windows and it's host is not connected to message window~~
* ~~fix deserializer on file-editor-view~~
* ~~re-add message panel. figure out how to avoid duplicate registration..~~
* ~~rewrite urls used to open up files such that it contains title to be displayed in file-editor-view?~~ddre
* ~~fix missing boxes when editing hosts~~
* ~~bug: only one item can be deleted at a time from hosts/open files~~
* hidden files are not returned with ftp regardless of settings
* ~~serialized/deserialized file-editor-view's does not push changes to host?~~
