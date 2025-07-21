#!/bin/bash

FILE="/opt/aquarium-lighting/config.json"
LOGFILE="$HOME/check-config.log"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

if [ -f "$FILE" ]; then
  SIZE=$(du -h "$FILE" | cut -f1)
  MSG="Fichier trouvé : $FILE\nTaille : $SIZE"
  yad --title="Résultat" --image=dialog-information --text="$MSG" --button=OK
  echo "[$NOW] OK - $FILE - $SIZE" >>"$LOGFILE"
else
  MSG="Fichier introuvable : $FILE"
  yad --title="Erreur" --image=dialog-error --text="$MSG" --button=OK
  echo "[$NOW] ERREUR - $FILE introuvable" >>"$LOGFILE"
fi
