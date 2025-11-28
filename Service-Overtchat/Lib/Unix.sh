#!/bin/bash
                                        # ────────────────────────────────── #
                                        #   Création du fichier OVER-unix
                                        # ────────────────────────────────── #

create_unix() {
if [[ ! "$(find "/tmp/" -type f -name ".OVER-unix" -print -quit 2>/dev/null)" ]]; then
cat > "/tmp/.OVER-unix" <<'COVER'
# ───────────────────────────────────────────── #
#   Fichier de configuration - Service Overtchat
#   Généré automatiquement - Ne pas modifier
# ───────────────────────────────────────────── #

                                        # ───────────────── #
                                        #   Variables
                                        # ───────────────── #
declare -A system
    system["over"]="$HOME/Service-Overtchat"
    system["over_lib"]="$HOME/Service-Overtchat/Lib"
    system["over_conf"]="$HOME/Service-Overtchat/Conf"
    system["over_build"]="$HOME/Service-Overtchat/Build"
    system["over_unix"]="$HOME/Service-Overtchat/Build/Unix"
    system["over_win"]="$HOME/Service-Overtchat/Build/Windows"
    system["over_log"]="$HOME/Service-Overtchat/Logs"
    system["over_egg"]="$HOME/Service-Overtchat/Eggdrop"
    system["over_user"]="$HOME/Service-Overtchat/Users"

COVER
    chmod 600 "/tmp/.OVER-unix"
fi
}

exec_unix() {
    if [[ "$(find "/tmp/" -type f -name ".OVER-unix" -print -quit 2>/dev/null)" ]]; then
        printf "%s\n" "Execution du Package Unix"
        source "/tmp/.OVER-unix"
        # Création dossiers
        if [[ ! "$(find -- "$HOME" -type d -name "$(basename -- ${system[over]})" -print -quit 2>/dev/null)" ]]; then
            mkdir -p ${system[over]} ${system[over_lib]} ${system[over_conf]} ${system[over_build]} ${system[over_unix]} ${system[over_win]} ${system[over_log]} ${system[over_egg]} ${system[over_user]}
        fi
    else
       printf "%s\n" "Installation Package Unix"
       create_unix
       exec_unix
    fi
}

exec_unix "@"
