#!/bin/bash
#Rôle : Permettre à l’inspecteur d’accepter ou refuser un immigrant.
USER="root"
PASSWORD="password"
DATABASE="grestin_db"

read -p "ID immigrant : " ID

mysql -u $USER -p$PASSWORD -D $DATABASE -e "SELECT * FROM immigrants WHERE immigrant_id='$ID';"

read -p "Décision (accepte/refuse) : " DECISION
read -p "Commentaire : " COMMENT
read -p "ID Inspecteur : " INSPECTEUR

mysql -u $USER -p$PASSWORD -D $DATABASE -e "
UPDATE immigrants SET statut='$DECISION' WHERE immigrant_id='$ID';
INSERT INTO decisions (immigrant_id, inspecteur_id, decision, commentaire)
VALUES ('$ID', $INSPECTEUR, '$DECISION', '$COMMENT');
"

echo "Décision enregistrée."
