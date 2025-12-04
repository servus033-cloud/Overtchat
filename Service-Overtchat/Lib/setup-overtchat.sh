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

                                        # ───────────────────────── #
                                        #   Message Installation
                                        # ───────────────────────── #

mess_install() {

cat <<'GLOB'

            ────────────────────────────────────────── ! Informations Générales ! ─────────────────────────────────────────────────────────

                     Nous allons procéder à l'installation de votre serveur Service-Overtchat pour le bon fonctionnement du programme.
                        
                       Ce script va vérifier que vous avez bien les packages nécessaires d'installés sur votre système.
                    Ensuite, il va configurer les fichiers de base et les dossiers nécessaires au bon fonctionnement du service.
                Enfin, il vous proposera de configurer les paramètres essentiels tels que la base de données, le serveur web, et les options de sécurité.

            ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

                              ! Assurez-vous d'avoir les droits administratifs (sudo) pour exécuter ce script. !

                         Tout sera géré automatiquement pour vous faciliter la tâche via Mariadb, Apache2 et PHP.
                 Si vous ne voulez pas de gestion Mysql/Mariadb, merci de ne pas utiliser ce script et de faire une installation manuelle.

            ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

                                           ! Panel Information Important Service-Overtchat !

                           Service-Overtchat permet le contrôle des paquets nécessaires au bon fonctionnement du programme.
               Si vous ne possèdez pas de droit ' root ', alors l'installation devra être arrêté, la commande ' sudo ' va être activé demandant vôtre mot de passe root !.

            ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

                                Voulez-vous vraiment lancer l'installation du programme Service-Overtchat ?

GLOB
}

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

load_config() {
    local conf_path
    conf_path=$(find "$INSTALL_HOME/Conf" \
                -type f -name "overtchat.conf" -print -quit 2>/dev/null)

    if [[ -z "$conf_path" ]]; then
        printf "%s\n" "Fichier de configuration introuvable. Veuillez installer correctement le programme."
        return 1
    fi

    if ! source "$conf_path"; then
        printf "%s\n" "Erreur : le fichier de configuration contient une erreur."
        return 1
    fi

    return 0
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

    # Vérifie si un argument --force est passé
    for arg in "$@"; do
        [[ "$arg" == "--force" ]] && FORCE_UPDATE=1
    done

    if [[ ! -d "$INSTALL_TMP/.git" ]]; then
        printf "%s\n" "Répertoire Git introuvable dans $INSTALL_TMP. Annulation mise à jour"
        exec "$INSTALL_BIN/./$0"
        return 1
    fi

    cd "$INSTALL_TMP" || { echo "Erreur chargement $INSTALL_TMP"; return 1; }

    git fetch origin "$INSTALL_BRANCH" >/dev/null 2>&1
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$INSTALL_BRANCH)

    if [[ "$LOCAL" != "$REMOTE" || $FORCE_UPDATE -eq 1 ]]; then
        if [[ $FORCE_UPDATE -eq 1 ]]; then
            printf "%s\n" "Mise à jour forcée activée !"
        else
            printf "%s\n" "Nouvelle version détectée !"
        fi

        if prompt_yn "Voulez-vous mettre à jour maintenant ? (Y/N) : "; then
            upgrade $FORCE_UPDATE
        else
            printf "%s\n" "Mise à jour annulée par l'utilisateur."
        fi
    else
        printf "%s\n" "Déjà à jour."
        clear
        sleep 2
    fi
}

upgrade() {
    FORCE=${1:-0}

    if ! load_config; then
        return 1
    fi

    cd "$INSTALL_TMP" || { 
        echo "Erreur chargement $INSTALL_TMP" >&2
        return 1 
    }

    if [[ "$FORCE" -eq 1 ]]; then
        # Force la mise à jour : écrase la branche locale
        printf "%s\n" "Récupération forcée de la dernière version depuis Git..."
        git fetch origin "$INSTALL_BRANCH" >/dev/null 2>&1
        git reset --hard origin/$INSTALL_BRANCH >/dev/null 2>&1
    else
        git pull origin $INSTALL_BRANCH >/dev/null 2>&1 || {
            printf "%s\n" "Erreur lors de la mise à jour depuis Git." >&2
            return 1
        }
    fi

    # Récupère la dernière version via Git tags
    git fetch --tags origin >/dev/null 2>&1
    latest_version=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')

    if [[ -z "$latest_version" ]]; then
        printf "%s\n" "Aucun tag trouvé sur le dépôt. Impossible de déterminer la dernière version." >&2
        return 1
    fi

    printf "%s\n" "Dernière version disponible : $latest_version"

    # Mise à jour du fichier de configuration
    conf_file="$INSTALL_HOME/Conf/overtchat.conf"
    build_date=$(date '+%Y-%m-%d %H:%M:%S')
    check_date=$(date '+%Y-%m-%d %H:%M:%S')

    sed -i "s|numeric\[\"version\"\]=\"[^\"]*\"|numeric[\"version\"]=\"$latest_version\"|" "$conf_file"
    sed -i "s|numeric\[\"build\"\]=\"[^\"]*\"|numeric[\"build\"]=\"$build_date\"|" "$conf_file"
    sed -i "s|numeric\[\"check\"\]=\"[^\"]*\"|numeric[\"check\"]=\"$check_date\"|" "$conf_file"

    printf "%s\n" "Mise à jour terminée vers la version $latest_version."

    # Installation suite à la mise à jour : ( à faire )

    # Relancer automatiquement si autoupdate activé
    if [[ "${numeric[autoupdate]}" -eq 1 ]]; then
        printf "%s\n" "Relancement automatique du programme..."
        exec "$INSTALL_BIN/./$0"
    fi
}

# Option 5
install() {
    # Contrôle si installation déjà faite
    if [[ -d "$INSTALL_HOME" ]]; then
        printf "%s\n" "Service déjà installé" >&2
        return 1
    fi

    printf "%s\n" "L'installation va commencer. Veuillez suivre les instructions à l'écran."

    sleep 2
    clear

    # Affichage du message d'installation
    mess_install

    if ! prompt_yn "Confirmez-vous le lancement de l'installation ? (Y/N) : "; then
        printf "%s\n" "Installation annulée par l'utilisateur."
        exit 0
    fi

    if ! command -v git &>/dev/null; then
        printf "%s\n" "Git n'est pas installé. Impossible d'installer. Veuillez installer Git via : sudo apt install git"
        exit 1
    fi

    printf "%s\n" "Installation [ en cours... ]"

    # Si dépot git pas encore installé
    if [[ ! -d "$INSTALL_TMP/.git" ]]; then
        printf "%s\n" "Clonage du dépôt..."
        if ! git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"; then
            printf "%s\n" "Erreur lors du clonage" >&2; exit 1
        fi
    fi

    # Rendre les scripts exécutables
    for dir in "$INSTALL_TMP/Install/bin" "$INSTALL_TMP/Service-Overtchat/Lib"; do
        if [[ -d "$dir" ]]; then
            search=$(find "$dir" -type f -name "*.sh" -print -quit 2>/dev/null)
            if [[ "$search" ]]; then
                find "$dir" -type f -name "*.sh" -exec chmod +x {} \;
            else
                printf "%s\n" "Aucun script .sh trouvé dans $dir. Installation impossible." >&2; exit 1
            fi
        fi
    done

    if [[ -f "$MAKEFILE" ]]; then
        printf "%s\n" "Lancement de la compilation..."
        if ! make -f "$MAKEFILE" "$MAKEVAR"; then
            printf "%s\n" "Erreur lors de la compilation" >&2; exit 1
        fi
        printf "%s\n" "Compilation terminée avec succès."
    else
        printf "%s\n" "Fichier MAKEFILE introuvable. Impossible de compiler." >&2; exit 1
    fi

    if [[ -f "$HOME/Service-Overtchat.tar.gz" ]]; then
        printf "%s\n" "Déploiement de l'archive..."
        if ! tar -xzf "$HOME/Service-Overtchat.tar.gz" -C "$HOME/"; then
            printf "%s\n" "Erreur lors du déploiement" >&2; exit 1
        fi
    else
        printf "%s\n" "Archive introuvable après compilation. Installation annulée." >&2
        exit 1
    fi

    printf "%s\n" "Déploiement terminé avec succès."
    rm -f "$HOME/Service-Overtchat.tar.gz"

    rm -f $HOME/$0
    printf "%s\n" "Installation terminée avec succès."
    sleep 2
    clear
    exec $INSTALL_BIN/./setup-overtchat
    exit 0
}

# Option 6
uninstall() {
    printf "%s\n" "Attention : Cette action supprimera entièrement Service-Overtchat et toutes ses données associées."
    if ! prompt_yn "Confirmez-vous la désinstallation complète ? (Y/N) : "; then
        printf "%s\n" "Annulation de la désinstallation"
        exit 0
    fi

    # Fonction pour supprimer et compter les fichiers
    delete_with_progress() {
        local dir="$1"
        # Récupère tous les fichiers/dossiers récursivement
        mapfile -t items < <(find "$dir" -mindepth 1)
        local total=${#items[@]}
        (( total == 0 )) && return

        printf "%s\n" "Désinstallation de $dir ($total éléments)..."

        local count=0
        for item in "${items[@]}"; do
            rm -rf "$item" 2>/dev/null
            ((count++))
            percent=$(( count * 100 / total ))
            printf "\rProgression : [%-50s] %d%%" "$(printf '%0.s#' $(seq 1 $((percent / 2))))" "$percent"
        done
        printf "\n"

        # Supprime le dossier racine après avoir vidé son contenu
        rm -rf "$dir" 2>/dev/null
    }

    # Supprimer les dossiers
    [[ -d "$INSTALL_HOME" ]] && delete_with_progress "$INSTALL_HOME"
    [[ -d "$INSTALL_TMP" ]] && delete_with_progress "$INSTALL_TMP"
    [[ -d "$INSTALL_SERVER" ]] && delete_with_progress "$INSTALL_SERVER"

    printf "%s\n" "Service-Overtchat a été désinstallé avec succès."
    printf "%s\n" "Merci d'avoir utilisé Service-Overtchat by SerVuS"
    printf "%s\n" "Pour nous retrouver : http://service.overtchat.free.fr"
    exit 0
}

# Option 7
setup_sql() {
    [[ ! -f "$INSTALL_BIN/sql" ]] && printf "%s\n" "Fichier ${shell[build_sql]} introuvable. Veuillez installer le programme d'abord." >&2; exit 1
    exec "$INSTALL_BIN/sql"
}

# Option 8
init_git() {
    printf "%s\n" "Initialisation du dépôt Git..."

    [[ -d "$INSTALL_TMP" ]] && rm -rf "$INSTALL_TMP"
    if ! git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"; then
        printf "%s\n" "Erreur lors du clonage" >&2; exit 1
    fi

    printf "%s\n" "Dépôt Git initialisé avec succès."
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