#!/bin/bash

# ----------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------

# Configure MySQL connection and authentication details
MYSQL_HOST='localhost'
MYSQL_USERNAME='mysqluser'
MYSQL_PASSWORD='mysqlpass'

# Specify the target directory where the backup shall be stored
TARGETDIR='/home/backupuser/mysql'

# Usually the following do not need to be changed
TMP="$TARGETDIR/tmp.sql.gz"
LOG=$(basename "$0")

# ----------------------------------------------------------------
# Script
# ----------------------------------------------------------------

# Prepare
mkdir -p "$TARGETDIR"

# Backup
mysqldump -h"$MYSQL_HOST" -u"$MYSQL_USERNAME" -p"$MYSQL_PASSWORD" --all-databases \
	| gzip \
	> "$TMP" \
	2> >( systemd-cat -p "info" -t "$LOG" )
result=${PIPESTATUS[1]}
if [[ $result -ne 0 ]]; then
	echo "Backup failed: mysqldump exited with code $result" | systemd-cat -p "crit" -t "$LOG"
	exit $result
fi

# Rotate
/usr/local/bin/rot -o "$TARGETDIR" -s '.sql.gz' "$TMP" > >(systemd-cat -p "info" -t "$LOG") 2>&1
result=${PIPESTATUS[1]}
if [[ $result -ne 0 ]]; then
	echo "Backup failed: rot exited with code $result" | systemd-cat -p "crit" -t "$LOG"
	exit $result
fi

# Clean up
rm "$TMP"
echo "Backup successful" | systemd-cat -p "notice" -t "$LOG"
exit 0
