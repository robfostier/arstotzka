#!/bin/bash
set -euo pipefail

UPLOAD_DIR="/srv/sftp/immigrant/uploads"
VALID_DIR="/srv/sftp/immigrant/valid"
INVALID_DIR="/srv/sftp/immigrant/invalid"
LOG="/var/log/cleanup.log"

mkdir -p "$VALID_DIR" "$INVALID_DIR"
touch "$LOG"

for archive in "$UPLOAD_DIR"/*.zip; do
    [ -e "$archive" ] || exit 0

    ID=$(basename "$archive" .zip)
    TMPDIR=$(mktemp -d)

    if ! unzip -qq "$archive" -d "$TMPDIR"; then
        echo "[REJECT] $ID : unzip failed" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
        rm -rf "$TMPDIR"
        continue
    fi

    # File presence check
    TXT=$(find "$TMPDIR" -type f -name "*.txt")
    PDFS=$(find "$TMPDIR" -type f -name "*.pdf")

    if [ -z "$TXT" ]; then
        echo "[REJECT] $ID : missing .txt" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
        rm -rf "$TMPDIR"
        continue
    fi

    if [ -z "$PDFS" ]; then
        echo "[REJECT] $ID : missing .pdf" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
        rm -rf "$TMPDIR"
        continue
    fi

    # ID check
    if ! find "$TMPDIR" -type f ! -name "*$ID*" | grep -q .; then
        mv "$archive" "$VALID_DIR"
        echo "[OK] $ID : archive valid" | tee -a "$LOG"
    else
        echo "[REJECT] $ID : ID mismatch in filenames" | tee -a "$LOG"
        mv "$archive" "$INVALID_DIR"
    fi

    rm -rf "$TMPDIR"
done
