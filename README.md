# remote-edit for atom.io

[![Build Status](https://travis-ci.org/sveale/remote-edit.svg?branch=master)](https://travis-ci.org/sveale/remote-edit)
[![Build status](https://ci.appveyor.com/api/projects/status/i1swrbog9vdk29uk)](https://ci.appveyor.com/project/SverreAleksandersen/remote-edit)


Atom package to browse and edit remote files using FTP and SFTP.

## Key features
* Add FTP/SFTP hosts graphically (FTPS not supported at the moment)
* Supports password, key and agent authentication
* Browse files through a select list
* Automatically upload file on save
* Multi-window support

## Agent authentication when using SSH
The package uses [ssh2](https://github.com/mscdex/ssh2) to connect to ssh servers, and also use the default construct in this package to authenticate with an agent.
On Windows, the agent will be set to "pageant", otherwise it assumes a *nix system and uses "process.env['SSH_AUTH_SOCK']" to get the agent.

This can be overriden in the settings.

## Keyboard shortcuts
### Windows / Linux
**ctrl-alt-b**: Select host

**ctrl-alt-o**: Show downloaded files

#### Mac OS X
**ctrl-cmd-b**: Select host

**ctrl-cmd-o**: Show downloaded files

#### Universal
While in "select host" mode you can delete a host by pressing "shift-d" or edit a host by pressing "shift-e".

While in "show downloaded files" mode you can remove a file from the list by pressing "shift-d". The file is deleted locally but not remotely.

## Screenshot
### Available commands
![Available commands](http://imgur.com/dS9a0CZ.png)

### Add a new FTP host
![Adding a new FTP host](http://imgur.com/dEVvXd6.png)

### Add a new SFTP host
![Adding a new SFTP host](http://imgur.com/4Kq3kwh.png)

### Edit existing host
![Editing an existing host](http://imgur.com/GgXh5qQ.png)

### Select host
![Select host](http://imgur.com/BediXn9.png)

### Browse host
![Browsing host](http://i.imgur.com/RwvMgFH.png)

### Show downloaded files
![Show open files](http://imgur.com/wpTTBQt.png)


## Settings window
![Settings window for remote-edit](http://imgur.com/8BG2Mz7.png)
