# Description

One liners might worth to keep.


### Archiving Downloads folder

Moves older than 30 days files from `~/Downloads` to `~/Downloads/xarchive`

```shell
find ~/Downloads -type f  ! -name '.*' -d 1 -mtime +30 -print -exec  mv '{}' ~/Downloads/xarchive/ \;
```

Archive folder is called xarchive for a reason. It appears at the bottom of the directory list.
