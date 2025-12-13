#!/bin/bash
#Rôle : Vérifier automatiquement les documents déposés par les immigrés.
UPLOAD_DIR="/srv/immigration/uploads"
VALID_DIR="/srv/immigration/valid"
INVALID_DIR="/srv/immigration/invalid"

for archive in "$UPLOAD_DIR"/*.zip; do
    [ -e "$archive" ] || continue

    ID=$(basename "$archive" .zip)
    TMPDIR=$(mktemp -d)
    unzip -q "$archive" -d "$TMPDIR"

    if ! ls "$TMPDIR"/*.txt >/dev/null 2>&1; then
        mv "$archive" "$INVALID_DIR"
        echo "[REFUS] $ID : aucun fichier TXT"
        rm -r "$TMPDIR"
        continue
    fi

    if ! ls "$TMPDIR"/*.pdf >/dev/null 2>&1; then
        mv "$archive" "$INVALID_DIR"
        echo "[REFUS] $ID : aucun fichier PDF"
        rm -r "$TMPDIR"
        continue
    fi

    mv "$archive" "$VALID_DIR"
    echo "[OK] $ID : documents conformes"

    rm -r "$TMPDIR"
done
