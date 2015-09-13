# remote-edit for atom.io

[![Build Status](https://travis-ci.org/sveale/remote-edit.svg?branch=master)](https://travis-ci.org/sveale/remote-edit)
[![Build status](https://ci.appveyor.com/api/projects/status/i1swrbog9vdk29uk)](https://ci.appveyor.com/project/SverreAleksandersen/remote-edit)


Atom package to browse and edit remote files using FTP and SFTP.

## Key features
* Add FTP/SFTP hosts graphically (FTPS not supported at the moment)
* Supports password, key and agent authentication
* Browse files through a select list
* Automatically upload file on save
* Multi-window support (ie. server settings and downloaded files are serialized and accessible across multiple Atom windows)

## Security concerns
 * By default, __all information is stored in cleartext to disk__. This includes passwords and passphrases.
 * Passwords and passphrases can alternatively be stored in the systems __default keychain__ by enabling it in the settings page for remote-edit. This is achieved using [node-keytar](https://github.com/atom/node-keytar) and might not work on all systems.

## Keyboard shortcuts
<kbd>Shift+e</kbd>
Edit hosts. Usable when selecting hosts (_Browse_).

<kbd>Shift+d</kbd>
Delete hosts or downloaded files. Usable when selecting hosts (_Browse_) or open files (_Show open files_).


### Windows / Linux specific
<kbd>Ctrl+Alt+b</kbd>
Select host.

<kbd>Ctrl+Alt+o</kbd>
Show downloaded files.

### Mac OS X specific
<kbd>Ctrl+Cmd+b</kbd>
Select host.

<kbd>Ctrl+Cmd+o</kbd>
Show downloaded files


## Tips and tricks
### SSH auth with password fails
On some sshd configuration (Mac OS X Mavericks), if _PasswordAuthentication_ is not explicitly set to yes, ssh server will not allow non-interactive password authentication. See [this issue](https://github.com/mscdex/ssh2/issues/154) for more in-depth information.

### Agent authentication when using SSH
The package uses [ssh2](https://github.com/mscdex/ssh2) to connect to ssh servers, and also use the default construct in this package to authenticate with an agent.
On Windows, the agent will be set to "pageant", otherwise it assumes a \ix system and uses "process.env['SSH_AUTH_SOCK']" to get the agent.
This can be overridden in the settings.

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
