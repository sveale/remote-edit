## 1.1.5 - fixes #15 and #12

## 1.1.4 - fixes #8

## 1.1.3 - bugfixes
* should fix a number of bugs. see commit messages

## 1.1.2 - bugfix issue #4
* developer error

## 1.1.1 - issue #3
* Added save/close buttons to "New host ..."

## 1.1.0 - Refactored to reduce startup time
* Implemented Q promises to enable deferred loading. Startup time of plugin reduced from ~500ms to ~10ms

## 1.0.0 -
* Remote files are opened in a special editor which displays a globe next to the name to emphasize that they're remote
* if selected auth is username/password and password is left blank it will prompt for password
* hosts and "open files" can be deleted from their respective views by pressing 'ctrl-d'
* added settings option to specify whether files should be automatically uploaded on save
* added keybindings for quick opening of most common features. see settings screenshot
* added message panel

## 0.1.1 - Bugfix
* fixed error where connections where left open even though host view had been closed
* fixed bug where file would only be written to remote once

## 0.1.0 - First Release
* FTP and SFTP browsing
* Download and upload of file
* List downloaded files
* Add new host (FTP/SFTP)
* SFTP auth with password, privatekey and user agent
* Hosts are persisted and are cross process
