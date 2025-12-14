#!/bin/bash
UPLOAD_DIR="/srv/sftp/immigrant/uploads"
VALID_DIR="/srv/sftp/immigrant/valid"
INVALID_DIR="/srv/sftp/immigrant/invalid"

for archive in "$UPLOAD_DIR"/*.zip; do
    [ -e "$archive" ] || continue

    ID=$(basename "$archive" .zip)
    TMPDIR=$(mktemp -d)
    unzip -q "$archive" -d "$TMPDIR"

    if ! ls "$TMPDIR"/*.txt >/dev/null 2>&1; then
        mv "$archive" "$INVALID_DIR"
        echo "[REJECT] $ID : can't find .txt"
        rm -r "$TMPDIR"
        continue
    fi

    if ! ls "$TMPDIR"/*.pdf >/dev/null 2>&1; then
        mv "$archive" "$INVALID_DIR"
        echo "[REJECT] $ID : can't find .pdf"
        rm -r "$TMPDIR"
        continue
    fi

    mv "$archive" "$VALID_DIR"
    echo "[OK] $ID : valid archive"

    rm -r "$TMPDIR"
done
