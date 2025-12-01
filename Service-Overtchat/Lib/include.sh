#!/bin/bash

# Chargement Librairie Conf
over_data="$HOME/Service-Overtchat/Conf/"

if [[ ! -v over_data ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Inconnu"
elif [[ -z "$over_data" ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Chaine vide"
elif [[ ! -d "$over_data" ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Dossier Inconnu"
else
    for pkg in $over_data; do
        var=$(find -- $pkg -type f -name "overtchat.conf" -print -quit 2>/dev/null)
        if [[ -n "$var" ]]; then
            source "$var"
        else
            printf "%s\n" "Aucun fichier de configuration trouvé dans le dossier $pkg"
        fi
    done
fi

# On affiche le résultat obtenu
printf "%s\n" "$over_conf"