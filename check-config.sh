#!/bin/bash

FILE="/opt/aquarium-lighting/config.json"

if [ -f "$FILE" ]; then
  echo "Fichier trouvé : $FILE"
  echo "Taille : $(du -h "$FILE" | cut -f1)"
else
  echo -e "\e[31m Fichier introuvable : $FILE\e[0m"
fi
