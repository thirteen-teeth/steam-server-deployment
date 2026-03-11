#!/bin/bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$(dirname "$0")/configs/vrising}"
CONFIG_FILES=("ServerHostSettings.json" "ServerGameSettings.json")
IMAGE="${VRISING_IMAGE:-trueosiris/vrising:latest}"
TMP_CONTAINER="vrising-settings-bootstrap"
TMP_SERVER_VOLUME="vrising-settings-bootstrap-server"
TMP_PERSIST_VOLUME="vrising-settings-bootstrap-persistent"
INIT_TIMEOUT_SECONDS="${INIT_TIMEOUT_SECONDS:-900}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-10}"

if ! command -v docker &>/dev/null; then
    echo "ERROR: docker is required for this script."
    exit 1
fi

mkdir -p "$CONFIG_DIR"

MISSING_FILES=()
for settings_file in "${CONFIG_FILES[@]}"; do
    local_path="$CONFIG_DIR/$settings_file"
    if [[ ! -f "$local_path" ]]; then
        MISSING_FILES+=("$settings_file")
    fi
done

if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
    echo "ERROR: All local V Rising settings files already exist in $CONFIG_DIR."
    echo "Refusing to overwrite your local config files."
    exit 1
fi

echo "==> Pulling $IMAGE (if needed)..."
docker pull "$IMAGE" >/dev/null

echo "==> Starting temporary bootstrap container..."
docker rm -f "$TMP_CONTAINER" >/dev/null 2>&1 || true
docker volume rm "$TMP_SERVER_VOLUME" "$TMP_PERSIST_VOLUME" >/dev/null 2>&1 || true
docker volume create "$TMP_SERVER_VOLUME" >/dev/null
docker volume create "$TMP_PERSIST_VOLUME" >/dev/null
docker run \
    --name "$TMP_CONTAINER" \
    --detach \
    --entrypoint /bin/bash \
    --mount type=volume,source="$TMP_SERVER_VOLUME",target=/mnt/vrising/server \
    --mount type=volume,source="$TMP_PERSIST_VOLUME",target=/mnt/vrising/persistentdata \
    --env TZ="UTC" \
    --env SERVERNAME="Settings Bootstrap" \
    --env WORLDNAME="settings_bootstrap" \
    --env GAMEPORT="9876" \
    --env QUERYPORT="9877" \
    --env WINEDEBUG="fixme-all" \
    "$IMAGE" \
    -c "sed -i 's/\\r//g' /start.sh && exec /bin/bash /start.sh" >/dev/null

cleanup() {
    docker rm -f "$TMP_CONTAINER" >/dev/null 2>&1 || true
    docker volume rm "$TMP_SERVER_VOLUME" "$TMP_PERSIST_VOLUME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

declare -A SOURCE_PATHS
DEADLINE=$((SECONDS + INIT_TIMEOUT_SECONDS))

echo "==> Waiting for V Rising settings files to be generated (timeout: ${INIT_TIMEOUT_SECONDS}s)..."
while ((SECONDS < DEADLINE)); do
    if ! docker ps --format '{{.Names}}' | grep -qx "$TMP_CONTAINER"; then
        break
    fi

    ALL_FOUND=true
    for settings_file in "${MISSING_FILES[@]}"; do
        if [[ -n "${SOURCE_PATHS[$settings_file]:-}" ]]; then
            continue
        fi

        CANDIDATE_PATHS=(
            "/mnt/vrising/persistentdata/Settings/$settings_file"
            "/mnt/vrising/server/VRisingServer_Data/StreamingAssets/Settings/$settings_file"
            "/VRisingServer_Data/StreamingAssets/Settings/$settings_file"
        )

        for candidate in "${CANDIDATE_PATHS[@]}"; do
            if docker exec "$TMP_CONTAINER" test -f "$candidate"; then
                SOURCE_PATHS["$settings_file"]="$candidate"
                break
            fi
        done

        if [[ -z "${SOURCE_PATHS[$settings_file]:-}" ]]; then
            SEARCH_RESULT=$(docker exec "$TMP_CONTAINER" sh -lc "find /mnt/vrising -type f -name '$settings_file' 2>/dev/null | head -n 1" || true)
            if [[ -n "$SEARCH_RESULT" ]]; then
                SOURCE_PATHS["$settings_file"]="$SEARCH_RESULT"
            else
                ALL_FOUND=false
            fi
        fi
    done

    if [[ "$ALL_FOUND" == "true" ]]; then
        break
    fi

    sleep "$POLL_INTERVAL_SECONDS"
done

FAILED_FILES=()
for settings_file in "${MISSING_FILES[@]}"; do
    if [[ -z "${SOURCE_PATHS[$settings_file]:-}" ]]; then
        FAILED_FILES+=("$settings_file")
    fi
done

if [[ ${#FAILED_FILES[@]} -gt 0 ]]; then
    echo "ERROR: Could not locate the following files after bootstrap startup:"
    printf '  - %s\n' "${FAILED_FILES[@]}"
    echo ""
    echo "Recent container logs:"
    docker logs --tail 120 "$TMP_CONTAINER" 2>/dev/null || true
    echo ""
    echo "Try increasing timeout: INIT_TIMEOUT_SECONDS=1800 make vrising-settings-init"
    exit 1
fi

for settings_file in "${MISSING_FILES[@]}"; do
    output_file="$CONFIG_DIR/$settings_file"
    source_path="${SOURCE_PATHS[$settings_file]}"
    echo "==> Exporting default $settings_file from $source_path"
    docker exec "$TMP_CONTAINER" cat "$source_path" > "$output_file"

    if ! grep -q '{' "$output_file"; then
        echo "ERROR: Extracted file does not look like JSON: $output_file"
        exit 1
    fi

    echo "==> Wrote local settings file: $output_file"
done

echo "==> Edit these files, then run: make vrising-settings-upload"
