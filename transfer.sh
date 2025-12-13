#!/bin/bash
#Rôle : Envoyer les dossiers validés au serveur interne + avertir les inspecteurs.
VALID_DIR="/srv/immigration/valid"
INTERNAL_SERVER="user@10.0.0.20"
INTERNAL_PATH="/srv/cases/waiting"

for file in "$VALID_DIR"/*.zip; do
    [ -e "$file" ] || continue

    scp "$file" "$INTERNAL_SERVER:$INTERNAL_PATH"

    echo "Nouveau dossier : $(basename "$file")" \
    | mail -s "Nouveau dossier immigrant" inspecteurs@grestin.local

    rm "$file"
    echo "[TRANSFER] $(basename "$file") transféré au serveur interne."
done
