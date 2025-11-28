#!/bin/bash

# Chargement Librairie Conf
over_data="$HOME/Service-Overtchat/Conf/*"

debug=0

if [[ ! -v over_data ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Inconnu"
elif [[ -z "$over_data" ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Chaine vide"
elif [[ ! -d "$over_data" ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Dossier Inconnu"
else
    for pkg in $over_data; do
        if [[ "$(find -- $pkg -type f -name "*.conf" -print 2>/dev/null)" ]]; then
            if [[ "$pkg" == "overtchat.conf" ]]; then
                source "$HOME/Service-Overtchat/Conf/$pkg"
                export over_conf="$pkg"
                : $((debug++))
            fi
        else
            exit 1
        fi
    done
fi

# On affiche le résultat obtenu
printf "%s\n" "$over_conf"

# Chargement de la Librairie Shell
over_data="$HOME/Service-Overtchat/Lib/*"

if [[ ! -v over_data ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Inconnu"
elif [[ -z "$over_data" ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Chaine vide"
elif [[ ! -d "$over_data" ]]; then
    printf "%s\n" "Erreur : Variable over_data érronée : Dossier Inconnu"
else
    for pkg in $over_data; do
        if [[ "$(find -- $pkg -type f -name "*.sh" -print 2>/dev/null)" ]]; then
            # On ignore le(s) fichier(s) concerné
            if [[ "$pkg" != "include.sh" ]]; then
                source "$HOME/Service-Overtchat/Lib/$pkg"
                export over_conf="$pkg"
                : $((debug++))
            fi
        else
            exit 1
        fi
    done
fi

# On affiche le résultat obtenu
printf "%s\n" "$over_conf"