#!/bin/bash

if [[ "$1" != "" && "$1" == "--debug" ]]; then
    set -xeuo pipefail
else
    set -euo pipefail
fi

# Dossier généraux
INSTALL_TMP="/tmp/.Overtchat" # dossier git
INSTALL_BRANCH="main" # branch git

INSTALL_HOME="$HOME/Service-Overtchat" # dossier install
INSTALL_SERVER="$HOME/Serveur-Overtchat" # dossier serveur

INSTALL_BIN="$INSTALL_HOME/bin/Lib" # librairie shell
REPO_URL="https://github.com/servus033-cloud/Overtchat.git" # lien du dépot

# Compilation
MAKEFILE="$INSTALL_TMP/Install/MAKEFILE"
MAKEVAR="release"


                                        # ────────────────────────────── #
                                        #   Initialisation du script
                                        # ────────────────────────────── #

# nettoyage de l'ecran
clear

# function declare
declare -A conf

cat <<'LOGOS'

                ##############################################
                ##	Service Overtchat New Generation    ##
                ##			V2.0		    ##
                ##############################################
                ##		Copyrigth by @SerVuS@ 	    ##
                ##    Contact : support.overtchat@free.fr   ##
                ##############################################

        Bienvenue sur le programme Service-Overtchat créer par SerVuS.

LOGOS

                                        # ────────────────────────────── #
                                        #   Gestion de la variable Log
                                        # ────────────────────────────── #

log() {
    local msg="$1"
    local timestamp logfile txt
    timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
    logfile="logs.dat"

    conf[log]=$(find "$INSTALL_HOME/Logs" -type f -name "$logfile" -print -quit 2>/dev/null)
    if [[ -n "${conf[log]}" ]]; then
        logfiles="$INSTALL_HOME/Logs/$logfile"
    else
        logfiles="$INSTALL_TMP/Service-Overtchat/Logs/$logfile"
    fi

    txt="[$timestamp] $msg"
    printf '%s\n' '$txt' >>"$logfiles"
}

                                        # ────────────────────────────── #
                                        #   Lancement des fonctions
                                        # ────────────────────────────── # 

# Validation
prompt_yn() {
    local msg="${1:-Confirmer ? (Y/N)}"
    local rep
    while true; do
        read -rp "$msg " rep
        case "$rep" in
        [YyOo]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) echo "Réponse invalide. Veuillez taper Y ou N." ;;
        esac
    done
}

prompt_continue() {
    printf "%s\n" ""
    read -rp "Appuyez sur Entrée pour continuer ou N pour quitter : " -n1 resp
    echo
    if [[ "$resp" =~ [Nn] ]]; then
        echo "Abandon."
        exit 0
    fi
}

                                        #############################
                                        # === Fonctions du menu === #
                                        #############################

# Option 1
view_logs() {
    logfile="logs.dat"

    if find "$INSTALL_HOME/Logs" -type f -name "$logfile" -print -quit 2>/dev/null; then
        logfile="$INSTALL_HOME/Logs/$logfile"
    else
        logfile="$INSTALL_TMP/Service-Overtchat/Logs/$logfile"
    fi

    printf "%s\n" "Contenu du fichier de logs : $logfile"
    # afficher ou message vide
    if [[ -s "$logfile" ]]; then
        cat "$logfile"
    else
        printf "%s\n" "[VIDE] Aucun log à afficher."
    fi

    return 0
}

# Option 2
funct_user() {
    printf "%s\n" "En travaux"
    return 0
}

# Option 3
updates() {
    FORCE_UPDATE=0

    
}

# Option 5
install() {
   echo "Veuillez passer par l'installateur < setup.sh >"
}

# Option 6
uninstall() {
    
}

# Option 7
setup_sql() {
    [[ ! -f "$INSTALL_BIN/sql" ]] && printf "%s\n" "Fichier ${shell[build_sql]} introuvable. Veuillez installer le programme d'abord." >&2; exit 1
    exec "$INSTALL_BIN/sql"
}

# Option 8
init_git() {
 
}

# Option 9
info_prog() {
    debug=0
    clear
    cat <<'LOCAL'
        Panel d'information générale du programme
LOCAL

    dirs=(
        "$INSTALL_TMP"
        "$INSTALL_HOME"
        "$INSTALL_TMP/.git"
    )

    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || { 
            echo "Dossier $dir : introuvable" >&2
            (( debug-- )) 
        }
    done

    # Scan fichier conf
    APP_FILE="$INSTALL_HOME/Conf/overtchat.conf"
    [[ -f "$APP_FILE" ]] || {
        echo "Fichier $APP_FILE : introuvable" >&2
        (( debug-- ))
    }

    [[ $debug -lt 0 ]] && { 
        echo "Une anomalie détectée. Veuillez refaire l'installation !" >&2; return 1
    }

    # Variables attendues
    needed_vars=(over info web numeric folders files shell server prog)

    # Vérification chargement
    need_source=0
    for var in "${needed_vars[@]}"; do
        if ! compgen -v | grep -qx "$var"; then
            need_source=1
            break
        fi
    done

    if (( need_source == 1 )); then
        if ! source "$APP_FILE"; then
            printf "%s\n" "Chargement fichier $APP_FILE impossible" >&2; return 1
        fi
    fi

    # Affichage version locale
    [[ -v numeric[version] ]] && {
        printf "%s\n" "Version du programme Actuel : ${numeric[version]}"
    }

    # Version Git
    git -C "$INSTALL_TMP" fetch --tags >/dev/null 2>&1
    REMOTE=$(git -C "$INSTALL_TMP" describe --tags --abbrev=0 2>/dev/null)
    [[ -n "$REMOTE" ]] && 
    printf "%s\n" "Version du programme Git : $REMOTE" \
    "Mise à jour disponible : $([[ ${numeric[version]} != $REMOTE ]] && echo Oui || echo Non)"

    # Options update/autoupdate
    [[ -v numeric[update] ]] &&
    printf "%s\n" "Mise à jour : $([[ ${numeric[update]} -eq 1 ]] && echo Activé || echo Désactivé)"

    [[ -v numeric[autoupdate] ]] &&
    printf "%s\n" "Mise à jour Automatique : $([[ ${numeric[autoupdate]} -eq 1 ]] && echo Activé || echo Désactivé)"
}

#                                ────────────────────
#                                |  FIN DES OPTIONS |
#                                ────────────────────

aff_panel() {
cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────
PANEL

# ─────────────────────────────────────────────────────────────
# 1) Aucune installation détectée
# /tmp/.Overtchat n'existe pas AND $HOME/Service-Overtchat n'existe pas
# ─────────────────────────────────────────────────────────────
if [[ ! -d "$INSTALL_TMP" && ! -d "$INSTALL_HOME" ]]; then
    printf "%s\n\n" "Installation non détectée. Veuillez installer le programme."
cat <<'PANEL'
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
PANEL

# ─────────────────────────────────────────────────────────────
# 2) /tmp absent mais dossier Git présent → anomalie Git
# ─────────────────────────────────────────────────────────────
elif [[ ! -d "$INSTALL_TMP" && -d "$INSTALL_HOME" ]]; then
    printf "%s\n" "Une anomalie concernant le dépôt Git a été détectée. Re-installation requise."
cat <<'PANEL'
        0) Quitter le programme : Quitter le panel et revenir au terminal
        6) Désinstaller le programme entièrement : Action irréversible
        8) Initialisation dépôt Git : Re-clonage du dépôt Git
PANEL

# ─────────────────────────────────────────────────────────────
# 3) /tmp présent mais dépôt absent → installation incomplète
# ─────────────────────────────────────────────────────────────
elif [[ -d "$INSTALL_TMP" && ! -d "$INSTALL_HOME" ]]; then
    printf "%s\n" "Installation incomplète détectée. Veuillez installer correctement le programme."
cat <<'PANEL'
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
        6) Désinstaller le programme entièrement : Action irréversible
PANEL

# ─────────────────────────────────────────────────────────────
# 4) Installation complète → contrôle Git & conf
# ─────────────────────────────────────────────────────────────
elif [[ -d "$INSTALL_TMP" && -d "$INSTALL_HOME" ]]; then

    # ─────────── Vérification dépôt Git
    if [[ -d "$INSTALL_TMP/.git" ]]; then
        printf "%s\n" "Installation détectée et complète. Contrôle configuration..."

        # ─────────── Vérification fichier conf
        conf_file=$(find "$INSTALL_HOME/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null)
        if [[ -z "$conf_file" ]]; then
            printf "%s\n" "Fichier de configuration introuvable. Veuillez réinstaller le programme."
            exit 1
        fi

        # Charger la conf
        source "$conf_file"

cat <<'PANEL'

Veuillez faire vôtre choix :

        0) Quitter le programme : Quitter le panel et revenir au terminal ( opérationnelle )
        1) Voir les logs du système : Affiche le contenu du fichier de log Systême Service-Overtchat et les logs des autres Services ( presque opérationnelle )
        2) ( Mode modifié : en travaux )
        3) Vérifier les mises à jour : Fait via GitHub si disponible ( bientôt opérationnelle)
        4) Activer/Désactiver mises à jour : Active ou désactive la gestion automatique des mises à jour ( en travaux )
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet ( en cours de finition )
        6) Désinstaller le programme entièrement : Action irréversible ( opérationnelle)
        7) Installation/Paramètre MariaDB : Lance le script de configuration de la base de données MariaDB ( en travaux )
        8) Initialisation dépôt Git : Re-clonage du dépôt Git ( opérationnelle uniquement si dépôt corrompu )
        9) Information global Service-Overtchat ( en développement )
PANEL

    else
        # ─────────── Git manquant → dépôt corrompu
        printf "%s\n" "Anomalie détectée dans le dépôt Git. Re-installation requise."
cat <<'PANEL'
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
        6) Désinstaller le programme entièrement : Action irréversible
        8) Initialisation dépôt Git : Re-clonage du dépôt Git
PANEL
    fi
fi
}

panels_loop() {
    local choice
    while true; do
    aff_panel
        read -rp "Entrez votre choix (0-9) : " choice
        case "$choice" in
        0)
            printf "%s\n" "Quitter le programme. À bientôt !"
            exit 0
            ;;
        1)
            view_logs
            ;;
        2)
            funct_user
            ;;
        3)
            updates
            ;;
        4)
            continue
            ;;
        5)
            install
            ;;
        6)
            uninstall
            ;;
        7)
            setup_sql
            clear
            aff_panel
            ;;
        8)
            init_git
            clear
            aff_panel
            ;;
        9)
            info_prog
            ;;
        *)
            printf "%s\n" "Choix invalide. Veuillez réessayer."
            ;;
        esac
    done
}

panels_loop "@"