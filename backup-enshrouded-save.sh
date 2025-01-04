#!/bin/bash

# Define the source directory
SOURCE_DIR="/var/lib/docker/volumes/enshrouded-persistent-data/_data"

# Define the backup directory
BACKUP_DIR="/tmp"

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get the current date and time in YYYY-MM-DD-HH-MM format
TIMESTAMP=$(date +"%Y-%m-%d-%H-%M")

# Define the backup file name
BACKUP_FILE="$BACKUP_DIR/backup-$TIMESTAMP.tar.gz"

# Create the tar.gz file
tar -czvf "$BACKUP_FILE" -C "$SOURCE_DIR" .

# Print a message indicating the backup is complete
echo "Backup completed: $BACKUP_FILE"