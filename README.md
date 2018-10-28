# Backup utilities

This repository contains simple but effective backup utilities for Linux servers.

Features:

* Data that shall be backed up is *pulled* from the server to the backup destination, so that no extra utilities (except `ssh` and `rsync`) need to be installed on the backed-up machine.
* Backups are rotated in daily, weekly, monthly, and yearly cycles. The number of retained backups per cycle can be configured. Each cycle can be disabled.
* All backups are incremental, which saves disk space (that is, if a file has not been changed, it will not be backed up again).
* Backups heavily rely on hard-links, a feature that is natively provided by many file systems. That means: no proprietary backup/compression/indexing format; all backups are saved as regular files to the disk. To recover a backup, it is enough to just copy the files contained in the folder representing the respective backup.
* No heavy dependencies: scripts are written in Bash, and only rely on `rsync` for copying files.

## dirbak

`dirbak` creates a file-wise back-up of the entire source directory at the given destination.
The back-up is created using hard links, so that the back-up is a full back-up (independent from other back-ups), but creates a hard link to a file if it already exists in another back-up. That way, no redundant copying is made.
The source directory and its contents will be linked to a newly created directory in $DESTINATION that is named after the current date by default, in YYYY-MM-DD format (even though the name can be changed).

When `dirbak` is run multiple times, a typical directory structure will look like this, for example:

```
backupfolder/
├─ 2018-01-01/
│  ├─ README.md
│  └─ src/
│     ├─ main.rs
│     └─ Cargo.toml
├─ 2018-01-02/
│  ├─ README.md
│  └─ src/
│     ├─ demo/
│     │  └─ mod.rs
│     ├─ main.rs
│     └─ Cargo.toml
├─ 2018-01-03/
│  ├─ README.md
│  └─ src/
│     ├─ demo/
│     │  ├─ test.rs
│     │  └─ mod.rs
│     ├─ main.rs
│     └─ Cargo.toml
└─ last [symlink to ./2018-01-03/]
```

All files that have not changed between the individual updates, hard-link to the same inode on the hard-disk (and thus consume almost no disk space).

The tool is used as
```bash
dirbak [OPTIONS] SOURCE DESTINATION
```
where:

* `SOURCE` is the source directory that shall be backed up. It can be a local path or a remote one (via SSH); in the latter case, it needs to be in a format accepted by rsync (e.g. `user@host:/path/to/dir`).
* `DESTINATION` is the destination direcory in which all backups are stored. It must be a local path.
* The option `--name=` allows you to specify a custom name for the backup. By default, it will be the current date in `YYYY-MM-DD` format.
* The option `--exclude=` (can occur multiple times) allows you to exclude a source file or folder from being backed up. All `--exclude` flags are directly passed to `rsync`.

## rot

`rot` is an utility that rotates a given file or folder by creating daily, weekly, monthly and yearly hard-links in dedicated folders in the output directory.
It only keeps a given number of copies for the daily, weekly, monthly and yearly links; all older links will be deleted.
Links will be named after the current date in the format `YYYY-MM-DD` (daily), `YYYY-WW` (weekly), `YYYY-MM` (monthly) and `YYYY` (yearly), respectively.
Optionally, a prefix and a suffix for the created links can be specified.

A typical folder structure will look like the following:

```
rotfolder/
├─ daily/
│  ├─ 2018-01-01/
│  ├─ 2018-01-02/
│  ├─ 2018-01-03/
│  ├─ 2018-01-04/
│  └─ 2018-01-05/
├─ weekly/
│  ├─ 2017-50/
│  ├─ 2017-51/
│  ├─ 2017-52/
│  ├─ 2018-01/
│  └─ 2018-02/
├─ monthly/
│  ├─ 2017-09/
│  ├─ 2017-10/
│  ├─ 2017-11/
│  ├─ 2017-12/
│  └─ 2018-01/
└─ yearly/
   ├─ 2016/
   ├─ 2017/
   └─ 2018/
```

The tool is used as
```bash
rot [OPTIONS] PATH
```
where:

* `PATH` is the path to the file or folder that shall be rotated. The file/folder itself will not be touched; only (recursive) hard links will be made. The path must be local.
* The option `--name=` allows you to specify a custom name for the backup. By default, it will be the current date in `YYYY-MM-DD` format.
* The option `--exclude=` (can occur multiple times) allows you to exclude a source file or folder from being backed up. All `--exclude` flags are directly passed to `rsync`.
* The option `--daily-num` specifies the number of daily copies that are kept.
* The option `--weekly-num` specifies the number of weekly copies that are kept.
* The option `--monthly-num` specifies the number of monthly copies that are kept.
* The option `--yearly-num` specifies the number of yearly copies that are kept.
* The option `--prefix` specifies the prefix that shall be prepended to the file name of the links.
* The option `--suffix` specifies the suffix that shall be appended to the file name of the links. Useful for specifying a file extension.
* The option `--out` specifies the folder in which the rotation copies are created (the folder which contains the `daily/`, `weekly/`, `monthly/` and `yearly/` sub-folders.
* The option `--daily-out` allows you to given another name to the `daily/` subfolder.
* The option `--weekly-out` allows you to given another name to the `weekly/` subfolder.
* The option `--monthly-out` allows you to given another name to the `monthly/` subfolder.
* The option `--yearly-out` allows you to given another name to the `yearly/` subfolder.
* The option `--now` specifies the date that shall be used to deduce the names of the rotation folders. Needs to be in a format that is accepted by `date`.
* If the option `--no-create-daily` is set, no daily copies are created.
* If the option `--no-create-weekly` is set, no weekly copies are created.
* If the option `--no-create-monthly` is set, no monthly copies are created.
* If the option `--no-create-yearly` is set, no yearly copies are created.
* If the option `--no-delete-daily` is set, no daily copies are deleted.
* If the option `--no-delete-weekly` is set, no weekly copies are deleted.
* If the option `--no-delete-monthly` is set, no monthly copies are deleted.
* If the option `--no-delete-yearly` is set, no yearly copies are deleted.

## Examples

Some example scripts are provided in [./examples/](examples/) that show how these scripts can be used in practise.
There are currently three examples:

* [backup-files.sh](examples/backup-files.sh): Backup of a folder on a remote server, and daily/weekly/monthly/yearly rotation of this backup.
* [backup-mysql.sh](examples/backup-mysql.sh): Backup of a MySQL dump on a remote server, and daily/weekly/monthly/yearly rotation of this dump.
* [backup-mysql-docker.sh](examples/backup-mysql-docker.sh): The same MySQL dump script, but this time for a MySQL server running in a Docker container.

## License

These utilities have been developed by Steve Muller and are licensed under an MIT license. See the [LICENSE](LICENSE.md) file for more information.
