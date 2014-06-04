* ~~Implement remote sync~~
  * ~~write metadata about remote file and host~~
  * ~~implement abstract write method in ftp/sftp~~
  * ~~listening for "save" events from files~~
  * ~~send open remote files to main-view and persist~~
* ~~review settings~~
* ~~figure out how to grab latest version of ftp from github with fixes~~
* ~~display open files~~
* ~~add status updates when files are updated~~
* look at how promises can be utilized in inter-process-data.coffee and other parts of the package
* **add password prompt if specified auth scheme and no password is present**
* when remote files are displayed show where they're from
  * ~~mark open remote files as remote~~
  * modify gutter to show origin
* keyboard shortcuts for deleting hosts/files
  * issue of persistence
  * showing keyboard shortcut in list
* optional prompt when remote files are saved
* remove subscription from host.coffee and place the logic in file-editor-view.coffee
