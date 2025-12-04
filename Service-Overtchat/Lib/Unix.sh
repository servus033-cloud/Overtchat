#!/bin/bash
PKG="$HOME/Service-Overtchat/tmp/"
                                        # ────────────────────────────────── #
                                        #   Création du fichier OVER-unix
                                        # ────────────────────────────────── #

create_unix() {
if [[ ! "$(find "$PKG" -type f -name ".OVER-unix" -print -quit 2>/dev/null)" ]]; then
cat > "$PKG/.OVER-unix" <<'COVER'
# ───────────────────────────────────────────── #
#   Fichier de configuration - Service Overtchat
#   Généré automatiquement - Ne pas modifier
# ───────────────────────────────────────────── #

declare -A system
    system["over"]="$HOME/Service-Overtchat" # Racine du programme
    system["over_tmp"]="$HOME/Service-Overtchat/tmp" # Dossier temporaire
    system["over_lib"]="$HOME/Service-Overtchat/Lib" # Librairies du programme
    system["over_conf"]="$HOME/Service-Overtchat/Conf" # Fichiers de configuration
    system["over_build"]="$HOME/Service-Overtchat/Build" # Fichiers de build
    system["over_unix"]="$HOME/Service-Overtchat/Build/Unix" # Fichiers Unix
    system["over_win"]="$HOME/Service-Overtchat/Build/Windows" # Fichiers Windows
    system["over_log"]="$HOME/Service-Overtchat/Logs" # Fichiers de logs
    system["over_egg"]="$HOME/Service-Overtchat/Eggdrop" # Fichiers Eggdrop
    system["over_user"]="$HOME/Service-Overtchat/Users" # Fichiers utilisateurs
    system["over_sql"]="$HOME/Service-Overtchat/SQL" # Fichiers SQL
    system["over_bin"]="$HOME/Service-Overtchat/bin" # Fichiers binaires
    system["over_web"]="$HOME/Service-Overtchat/Web" # Fichiers web
    system["over_git"]="/tmp/.Overtchat/.git" # Fichiers git primaires

COVER
    chmod 600 "$PKG/.OVER-unix"
fi
}

exec_unix() {
    for arg in "${system[@]}"; do
        export "$arg"
    done
}

exec_unix "@"
