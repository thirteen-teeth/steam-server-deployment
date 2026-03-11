#!/bin/bash
set -euo pipefail

SSH_KEY="${SSH_KEY:-$HOME/.ssh/my-key-pair}"
REMOTE_USER="${REMOTE_USER:-ubuntu}"
REMOTE_HOST="${REMOTE_HOST:-steam.thirteenteeth.com}"
LOCAL_DIR="${LOCAL_DIR:-$(dirname "$0")/configs/vrising}"
REMOTE_DIR="/opt/game-configs/vrising"
SETTINGS_FILES=("ServerHostSettings.json" "ServerGameSettings.json")
SSH="ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST"

if [[ ! -d "$LOCAL_DIR" ]]; then
    echo "ERROR: Local settings directory not found: $LOCAL_DIR"
    echo "Run: make vrising-settings-init"
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "ERROR: jq is required to validate JSON. Run: sudo apt install jq"
    exit 1
fi

LOCAL_FILES=()
for settings_file in "${SETTINGS_FILES[@]}"; do
    local_file="$LOCAL_DIR/$settings_file"
    if [[ -f "$local_file" ]]; then
        jq empty "$local_file"
        LOCAL_FILES+=("$local_file")
    fi
done

if [[ ${#LOCAL_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No local V Rising settings files found in: $LOCAL_DIR"
    echo "Expected one or both of: ${SETTINGS_FILES[*]}"
    echo "Run: make vrising-settings-init"
    exit 1
fi

for local_file in "${LOCAL_FILES[@]}"; do
    settings_file=$(basename "$local_file")
    remote_file="$REMOTE_DIR/$settings_file"
    tmp_file="/tmp/${settings_file}.$$"

    echo "==> Uploading $local_file to $REMOTE_HOST"
    scp -i "$SSH_KEY" "$local_file" "$REMOTE_USER@$REMOTE_HOST:$tmp_file"

    echo "==> Installing settings file at $remote_file"
    $SSH "sudo mkdir -p '$REMOTE_DIR' && sudo mv '$tmp_file' '$remote_file' && sudo chmod 0644 '$remote_file'"
done

echo "==> Applying settings to container"
$SSH "if sudo docker ps -a --format '{{.Names}}' | grep -qx 'vrising-server'; then sudo docker restart vrising-server >/dev/null && sudo docker ps --filter name=vrising-server --format '{{.Names}}: {{.Status}}'; else echo 'vrising-server container not found yet; run make apply to create/start it.'; fi"

echo "==> Done. Active settings source directory: $REMOTE_DIR"
