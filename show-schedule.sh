#!/bin/bash

CONFIG="/opt/aquarium-lighting/config.json"
LOGFILE="$HOME/aquarium.log"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

DAY=$(LC_TIME=C date +%A | tr '[:upper:]' '[:lower:]')
if [ ! -f "$CONFIG" ]; then
  yad --title="Erreur" --image=dialog-error --text="Fichier $CONFIG introuvable"
  echo "[$NOW] ERREUR - Fichier $CONFIG introuvable" >>"$LOGFILE"
  exit 1
fi

MODE=$(jq -r '.mode' "$CONFIG")
ON=$(jq -r ".jours.$DAY.on" "$CONFIG")
OFF=$(jq -r ".jours.$DAY.off" "$CONFIG")

MSG="Mode actuel : $MODE\n\n🗓️ Aujourd'hui ($DAY)\n💡 Allumage : $ON\n🌙 Extinction : $OFF"

yad --title="État de l'aquarium" --image=dialog-information --text="$MSG" --button="Fermer"

echo "[$NOW] CONSULTATION - $DAY - ON: $ON OFF: $OFF (mode: $MODE)" >>"$LOGFILE"
