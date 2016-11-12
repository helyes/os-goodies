# Link files

A config driven script to symlink files.<br>
Allows to easily version manage files across the file system from one spot. See example below.

## Usage

```sh
$ ./link-files.sh link|init [-v] [-d|-dry] config_file
```
### Parameters
- `init`: initializes  file repository
- `link`: create symlinks from repository
- config_file: the config <br>

### Options
- `-v|--verbose`: verbose mode
- `-d|-dry`: prints commands only, no actual file operations

Optional parameters can not be combined. For example `-dv` will not enable verbose and dry run mode. Use `-d -v` format.

## Warning

Use this script only if you know what are you doing. Symlinks are forced to make updates easier. As a result if a file already exists at the symlink location, it will get overwritten.

## The config file

### File layout

List of `destination=source folder` entries.<br>
Empty lines and lines starting with # are ignored

``target_file=source_folder``

## Example - Typical workflow


### Config file
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

# For testing
# Create a dummy file
# echo "blah" > ~/tmp/originallocation/project.txt
# Reset
# rm ~/tmp/originallocation/*.*; mv ~/tmp/filerepo/*.*  ~/tmp/originallocation/
# Check
# ls -l ~/tmp/originallocation/project.txt  ~/tmp/filerepo/project.txt
# Content
# cat ~/tmp/filerepo/project.txt; cat ~/tmp/filerepo/project.txt


~/tmp/originallocation/project.txt=~/tmp/filerepo
```

### 1. Init
Move files from current - desired - location to a repository folder

Start point
```sh
$ ls -l ~/tmp/originallocation/project.txt  ~/tmp/filerepo/project.txt
ls: /Users/andras/tmp/filerepo/project.txt: No such file or directory
-rw-r--r--  1 andras  staff  5 12 Nov 19:11 /Users/andras/tmp/originallocation/project.txt
```

Project.txt file sits in `/Users/andras/tmp/originallocation` folder.  `/Users/andras/tmp/filerepo/project.txt` does not exist.

Run script as below assuming the config file called `playground.conf`
```sh
./link-files.sh init  playground.conf

```

**Output**

```
Parsing config file: playground.conf


Success: 1 entries loaded from playground.conf

Initializing...

Executing mv -v /Users/andras/tmp/originallocation/project.txt /Users/andras/tmp/filerepo/project.txt
/Users/andras/tmp/originallocation/project.txt -> /Users/andras/tmp/filerepo/project.txt
Success: /Users/andras/tmp/originallocation/project.txt moved to /Users/andras/tmp/filerepo/project.txt
```

File has been moved from /tmp/originallocation/project.txt to /Users/andras/tmp/filerepo folder

```sh
ls -l ~/tmp/originallocation/project.txt  ~/tmp/filerepo/project.txt
ls: /Users/andras/tmp/originallocation/project.txt: No such file or directory
-rw-r--r--  1 andras  staff  5 12 Nov 19:11 /Users/andras/tmp/filerepo/project.txt
```

### 2. Link
Link files back to original location

Run script as below with `link` parameter
```sh
./link-files.sh link  playground.conf

```

**Output**
```
Parsing config file: playground.conf


Success: 1 entries loaded from playground.conf

Linking files...

Executing ln -sfv /Users/andras/tmp/filerepo/project.txt /Users/andras/tmp/originallocation/project.txt
/Users/andras/tmp/originallocation/project.txt -> /Users/andras/tmp/filerepo/project.txt
Success: /Users/andras/tmp/originallocation/project.txt -> /Users/andras/tmp/filerepo/project.txt
```

File from `/Uses/andras/tmp/filerepo` now linked back to original location `/tmp/originallocation/project.txt` as a symlink

```
19:28 $ ls -l ~/tmp/originallocation/project.txt  ~/tmp/filerepo/project.txt
-rw-r--r--  1 andras  staff   5 12 Nov 19:11 /Users/andras/tmp/filerepo/project.txt
lrwxr-xr-x  1 andras  staff  38 12 Nov 19:28 /Users/andras/tmp/originallocation/project.txt -> /Users/andras/tmp/filerepo/project.txt
```

### Example - Symlinking user dot files

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
$ ./link-files init user-dot-files.conf
$ ./link-files link user-dot-files.conf
```

It is strongly recommended to run the above scripts first with `-d` parameter to see what the result would be.

### Result
`~/.profile` is a symlink to `/work/.config/home/.profile` <br>
`~/.bash_aliases` is a symlink to `/work/.config/home/.bash_aliases`
