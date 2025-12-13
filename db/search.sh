#!/bin/bash
#Rôle : Permettre de rechercher un immigrant et afficher son statut.
USER="root"
PASSWORD="password"
DATABASE="grestin_db"

read -p "ID Immigrant : " ID

mysql -u $USER -p$PASSWORD -D $DATABASE -e "
SELECT * FROM immigrants WHERE immigrant_id='$ID';
SELECT * FROM decisions WHERE immigrant_id='$ID' ORDER BY date_decision DESC LIMIT 1;
"
