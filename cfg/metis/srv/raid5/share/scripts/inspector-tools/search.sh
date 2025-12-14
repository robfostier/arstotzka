#!/bin/bash

ID="$1"
LOG="/mnt/nas/cases/cases.log"

if [ -z "$ID" ]; then
  echo "Usage: ./search.sh <ID>"
  exit 1
fi

if grep -q "REJECTED , ID $ID" "$LOG"; then
  echo "DENIED"
  exit 0
fi

echo "AUTHORIZED"
exit 0
