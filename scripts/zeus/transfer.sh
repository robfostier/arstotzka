#!/bin/bash
VALID_DIR="/srv/sftp/immigrant/valid"
INTERNAL_SERVER="tech@grestin.local@10.0.0.20"
INTERNAL_PATH="/srv/cases/pending"

for file in "$VALID_DIR"/*.zip; do
    [ -e "$file" ] || continue

    scp "$file" "$INTERNAL_SERVER:$INTERNAL_PATH"

    echo "New case : $(basename "$file")" \
    | mail -s "New case" inspector@grestin.local

    rm "$file"
    echo "[TRANSFER] $(basename "$file") transfered to internal server."
done
