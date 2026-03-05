#!/bin/bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-$HOME/.ssh/my-key-pair}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_HOST="${REMOTE_HOST:-steam.thirteenteeth.com}"
BACKUP_BASE="${BACKUP_BASE:-$HOME/backups/steam-servers}"
TERRAFORM_DIR="${TERRAFORM_DIR:-$(dirname "$0")}"
SSH="ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST"

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required but not installed. Run: sudo apt install jq"
    exit 1
fi

echo "==> Reading game config from Terraform..."
BACKUP_CONFIG=$(terraform -chdir="$TERRAFORM_DIR" output -json backup_config)

# --- Resolve backup directory ---
if [[ -z "${BACKUP_DATE:-}" ]]; then
    BACKUP_DIR=$(ls -1d "$BACKUP_BASE"/*/  2>/dev/null | sort | tail -1)
    if [[ -z "$BACKUP_DIR" ]]; then
        echo "ERROR: No backups found in $BACKUP_BASE"
        exit 1
    fi
    echo "==> No BACKUP_DATE specified, using latest: $(basename "$BACKUP_DIR")"
else
    BACKUP_DIR="$BACKUP_BASE/$BACKUP_DATE"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "ERROR: Backup not found: $BACKUP_DIR"
        echo ""
        echo "Available backups:"
        ls -1d "$BACKUP_BASE"/*/  2>/dev/null | sort || echo "  (none)"
        exit 1
    fi
fi

# --- Resolve games to restore ---
if [[ -n "${GAME:-}" ]]; then
    if ! echo "$BACKUP_CONFIG" | jq -e --arg g "$GAME" '.[$g]' &>/dev/null; then
        echo "ERROR: Game '$GAME' not found in Terraform config."
        echo "Known games: $(echo "$BACKUP_CONFIG" | jq -r 'keys | join(", ")')"
        exit 1
    fi
    GAMES="$GAME"
else
    GAMES=$(echo "$BACKUP_CONFIG" | jq -r 'keys[]')
fi

echo "==> Restore source: $BACKUP_DIR"
echo "==> Games to restore: $(echo "$GAMES" | tr '\n' ' ')"
echo ""
read -r -p "Are you sure you want to restore? This will stop the affected containers. [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

while IFS= read -r game; do
    container=$(echo "$BACKUP_CONFIG" | jq -r --arg g "$game" '.[$g].container')
    volumes=$(echo "$BACKUP_CONFIG" | jq -r --arg g "$game" '.[$g].volumes[]')

    echo ""
    echo "==> [$game] Stopping $container..."
    $SSH "sudo docker stop $container" || echo "    ($container was not running)"

    while IFS= read -r volume; do
        echo "==> [$game] Restoring $volume..."
        rsync -avz --progress --delete \
            -e "ssh -i $SSH_KEY" \
            "$BACKUP_DIR/$volume/" \
            "$REMOTE_USER@$REMOTE_HOST:/var/lib/docker/volumes/$volume/_data/"
    done <<< "$volumes"

    echo "==> [$game] Restarting $container..."
    $SSH "sudo docker start $container"
    echo "==> [$game] Done."
done <<< "$GAMES"

echo ""
echo "==> Restore complete."
