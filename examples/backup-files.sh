#!/bin/bash

# ----------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------

# Specify the source directory that shall be backed up; this path can be local or remote (SSH)
SOURCEDIR='backupuser@remoteserver:/etc/'

# Specify the target directory where the backup shall be stored
TARGETDIR='/home/backupuser/files'

# Usually the following do not need to be changed
TARGETDIR_DAILY="$TARGETDIR/daily"
BACKUP_NAME=$(date +%Y-%m-%d)
BACKUP_PATH="$TARGETDIR_DAILY/$BACKUP_NAME"
LOG=$(basename "$0")

# ----------------------------------------------------------------
# Script
# ----------------------------------------------------------------

# Make sure that the backup does not exist already; or else we risk merging two backups
if [[ -e "$BACKUP_PATH" ]]; then
	echo "Backup at $BACKUP_PATH already exists; aborting." | systemd-cat -p "crit" -t "$LOG"
	exit 1
fi

# Prepare
mkdir -p "$TARGETDIR"

# Backup to ./daily/
/usr/local/bin/dirbak --name "$BACKUP_NAME" "$SOURCEDIR" "$TARGETDIR_DAILY" > >(systemd-cat -p "info" -t "$LOG") 2>&1
result=$?
if [[ $result -ne 0 ]]; then
	echo "Backup failed: dirbak exited with code $result" | systemd-cat -p "crit" -t "$LOG"
	exit $result
fi

# Rotate the newly created backup
# Don't create a daily backup rotation, since out original backup has already been made to the ./daily folder
/usr/local/bin/rot -o "$TARGETDIR" --no-create-daily --suffix '' "$BACKUP_PATH" > >(systemd-cat -p "info" -t "$LOG") 2>&1
result=$?
if [[ $result -ne 0 ]]; then
	echo "Backup failed: rot exited with code $result" | systemd-cat -p "crit" -t "$LOG"
	exit $result
fi

# Done
echo "Backup successful" | systemd-cat -p "notice" -t "$LOG"
exit 0
