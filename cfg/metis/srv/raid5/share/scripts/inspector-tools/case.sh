#!/bin/bash

ACTION="$1"
CASE="$2"
ID="$3"
BASE="/mnt/nas/cases"
LOG="$BASE/cases.log"

if [ -z "$ACTION" ] || [ -z "$CASE" ] || [ -z "$ID" ]; then
  echo "Usage: ./case.sh <accept|reject> <case.zip> <ID>"
  exit 1
fi

case "$ACTION" in
  accept)
    DEST="accepted"
    STATUS="ACCEPTED"
    ;;
  reject)
    DEST="rejected"
    STATUS="REJECTED"
    ;;
  *)
    echo "Usage: ./case.sh <accept|reject> <case.zip> <ID>"
    exit 1
    ;;
esac

mv "$BASE/pending/$CASE" "$BASE/$DEST/" || {
  echo "Error: cannot move $CASE"
  exit 1
}

echo "$(date) $STATUS , ID $ID $CASE by $USER" >> "$LOG"

echo "AUTHORIZED"
exit 0
