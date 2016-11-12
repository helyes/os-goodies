# Link files

A config driven script to symlink files.<br>
Allows to easily version manage files across the file system from one spot. See example below.

## Usage

```sh
$ ./link-files.sh user-dot-files.conf
```

## Warning

Use this script only if you know what are you doing. Symlinks are forced to make updates easier. As a result if a file already exists at the symlink location, it will get overwritten.

## The config file

### File layout

List of `destination=source folder` entries.<br>
Empty lines and lines starting with # are ignored

``[target file]=[source folder]``

### Example

Symlinking user dot files

```sh
################################################################################
#                                                                              #
# File layout                                                                  #
# -----------                                                                  #
#                                                                              #
# <target>=<source folder>                                                     #
#                                                                              #
# Example:                                                                     #
# ~/.afile.conf=~/configfiles                                                  #
#                                                                              #
# Will result ~/.afile.conf symlink that points to ~/configfiles/.afile.conf   #
#                                                                              #
################################################################################

~/.profile=~/work/.config/home/
~/.bash_aliases=~/work/.config/home

```

### Command

```sh
$ ./link-files user-dot-files.conf
```

### Result
`~/.profile` is a symlink to `/work/.config/home/.profile` <br>
`~/.bash_aliases` is a symlink to `/work/.config/home/.bash_aliases`
