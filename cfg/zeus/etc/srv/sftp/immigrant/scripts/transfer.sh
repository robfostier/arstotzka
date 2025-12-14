#!/bin/bash
set -euo pipefail

VALID_DIR="/srv/sftp/immigrant/valid"
INTERNAL_USER="tech"
INTERNAL_HOST="10.0.0.20"
INTERNAL_PATH="/srv/raid5/share/cases/pending"
LOG="/var/log/transfer.log"

touch "$LOG"

for file in "$VALID_DIR"/*.zip; do
    [ -e "$file" ] || exit 0

    BASENAME=$(basename "$file")

    if scp "$file" "$INTERNAL_USER@$INTERNAL_HOST:$INTERNAL_PATH/"; then
        echo "[TRANSFER] $BASENAME transferred" | tee -a "$LOG"

        echo "New immigration case received: $BASENAME" \
        | mail -s "New case pending validation" inspector@grestin.local

        rm -f "$file"
    else
        echo "[ERROR] Failed to transfer $BASENAME" | tee -a "$LOG"
    fi
done
