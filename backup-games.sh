#!/bin/bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-$HOME/.ssh/my-key-pair}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_HOST="${REMOTE_HOST:-steam.thirteenteeth.com}"
BACKUP_BASE="${BACKUP_BASE:-$HOME/backups/steam-servers}"
TERRAFORM_DIR="${TERRAFORM_DIR:-$(dirname "$0")}"
BACKUP_DIR="$BACKUP_BASE/$(date +%Y-%m-%d_%H-%M)"
SSH="ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST"

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not installed. Run: sudo apt install jq"
    exit 1
fi

echo "==> Reading game config from Terraform..."
BACKUP_CONFIG=$(terraform -chdir="$TERRAFORM_DIR" output -json backup_config)
GAMES=$(echo "$BACKUP_CONFIG" | jq -r 'keys[]')

echo "==> Stopping game containers..."
while IFS= read -r game; do
    container=$(echo "$BACKUP_CONFIG" | jq -r --arg g "$game" '.[$g].container')
    echo "    Stopping $container..."
    $SSH "sudo docker stop $container" || echo "    ($container was not running)"
done <<< "$GAMES"

echo "==> Starting backup to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

while IFS= read -r game; do
    volumes=$(echo "$BACKUP_CONFIG" | jq -r --arg g "$game" '.[$g].volumes[]')
    while IFS= read -r volume; do
        echo "==> Backing up $volume..."
        rsync -avz --progress \
            -e "ssh -i $SSH_KEY" \
            "$REMOTE_USER@$REMOTE_HOST:/var/lib/docker/volumes/$volume/_data/" \
            "$BACKUP_DIR/$volume/"
        echo "==> $volume done."
    done <<< "$volumes"
done <<< "$GAMES"

echo "==> Restarting game containers..."
while IFS= read -r game; do
    container=$(echo "$BACKUP_CONFIG" | jq -r --arg g "$game" '.[$g].container')
    echo "    Starting $container..."
    $SSH "sudo docker start $container"
done <<< "$GAMES"

echo ""
echo "==> All backups complete: $BACKUP_DIR"
echo "==> Disk usage:"
du -sh "$BACKUP_DIR"/*
