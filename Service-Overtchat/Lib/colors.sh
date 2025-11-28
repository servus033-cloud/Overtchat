#!/bin/bash

                                        # ────────────────────────────────── #
                                        #   Création du fichier colors.conf
                                        # ────────────────────────────────── #

create_colors_conf() {
if [[ ! "$(find "$HOME/Service-Overtchat/Conf" -type f -name "colors.conf" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "Création du fichier colors.conf [ en cours... ]"
    log "Création du fichier colors.conf (Code erreur : 048) [en cours]"
    sleep 2

cat >"$HOME/Service-Overtchat/Lib/colors.conf" <<'COLOR'
# === Fonctions de base ===
std() { echo -e "\e[0m $1"; }
valid() { echo -e "\e[32m[VALIDE]\e[0m $1"; }
warn() { echo -e "\e[33m[WARNING]\e[0m $1"; } 
error() { echo -e "\e[31m[ERROR]\e[0m $1"; } 
check() { echo -e "\e[36m[CHECK]\e[0m $1"; } 
COLOR

    printf "%s\n" "Création du fichier colors.conf [ terminé ]"
    log "Création du fichier colors.conf (Code erreur : 048) [validé]"
fi
}