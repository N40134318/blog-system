#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 [dev|prod] /path/to/blog-system-migration-xxxx.tar.gz"
    exit 1
fi

TARGET_ENV="$1"
ARCHIVE_PATH="$2"
PROJECT_DIR="/opt/devplatform/projects/blog-system"
RESTORE_SCRIPT="$PROJECT_DIR/scripts/restore-migration.sh"
SWITCH_SCRIPT="$PROJECT_DIR/scripts/switch-env.sh"

if [ ! -f "$RESTORE_SCRIPT" ]; then
    echo "[ERROR] restore script not found: $RESTORE_SCRIPT"
    exit 1
fi

if [ ! -f "$SWITCH_SCRIPT" ]; then
    echo "[ERROR] switch script not found: $SWITCH_SCRIPT"
    exit 1
fi

case "$TARGET_ENV" in
    dev)
        CHOICE="1"
        ;;
    prod)
        CHOICE="2"
        ;;
    *)
        echo "Usage: $0 [dev|prod] /path/to/blog-system-migration-xxxx.tar.gz"
        exit 1
        ;;
esac

echo "[INFO] restore target env: $TARGET_ENV"
printf '%s\n' "$CHOICE" | bash "$RESTORE_SCRIPT" "$ARCHIVE_PATH"

echo "[INFO] switch nginx after restore"
bash "$SWITCH_SCRIPT" "$TARGET_ENV"

echo "[INFO] restore + switch finished: $TARGET_ENV"
