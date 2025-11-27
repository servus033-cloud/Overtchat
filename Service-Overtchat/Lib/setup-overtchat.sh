#!/usr/bin/env bash

if [[ "$1" != "" && "$1" == "--debug" ]]; then
    set -xeuo pipefail
else
    set -euo pipefail
fi

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

    $(find "$HOME/Overtchat/Service-Overtchat/Logs" -type f -name "$logfile" -print -quit 2>/dev/null) && {
        logfile="$HOME/Overtchat/Service-Overtchat/Logs/$logfile"
    } || {
        logfile="/tmp/log~overtchat.dat"
    }

    txt="[$timestamp] $msg"
    printf '%s\n' '$txt' >>"$logfile"
}

load_config() {
    conf[over]=$(find "$HOME/Overtchat/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null)
    if [[ -z "${conf[over]}" ]]; then
        printf "%s\n" "Fichier de configuration introuvable. Veuillez installer correctement le programme."
        return 1
    fi
    source "${conf[over]}"
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

control_install_folders() {
    local folders="Service-Overtchat Build Unix IriX Windows Lib Conf Eggdrop Logs"
    for dir in $folders; do
        [[ ! find "$HOME" -type d -name "$dir" -print -quit 2>/dev/null ]] && {
            printf "%s\n" "Dossier $dir introuvable. Veuillez installer correctement le programme."
            return 1
        }
    done
    return 0
}

                                        #############################
                                        # === Fonctions du menu === #
                                        #############################

# Option 1
view_logs() {
    logfile="logs.dat"

    $(find "$HOME/Overtchat/Service-Overtchat/Logs" -type f -name "$logfile" -print -quit 2>/dev/null) && {
        logfile="$HOME/Overtchat/Service-Overtchat/Logs/$logfile"
    } || {
        logfile="/tmp/log~overtchat.dat"
    }

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
    control_install_folders || return 1
    load_config || return 1
                                # Mise à jour Git #

    APP_DIR="$HOME/Overtchat"
    BRANCH="main"

    cd "$APP_DIR" || exit 1

    git fetch origin "$BRANCH"
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH)

    if [[ "$LOCAL" != "$REMOTE" ]]; then
        printf "%s\n" "Nouvelle version détectée !"
        git pull origin "$BRANCH"
        printf "%s\n" "Mise à jour terminée."
    else
        printf "%s\n" "Déjà à jour."
    fi
}

# Option 4
upgrade() {
    # Vérifie que les dossiers essentiels sont présents
    control_install_folders || return 1

    # Cherche le fichier de configuration
    load_config || return 1
    
    printf "%s\n" "Version actuelle : ${numeric[version]}, mise à jour automatique : ${numeric[autoupdate]}"

    REPO_DIR="$HOME/Overtchat/Service-Overtchat"
    if [[ ! -d "$REPO_DIR/.git" ]]; then
        printf "%s\n" "Répertoire Git introuvable dans $REPO_DIR. Impossible de récupérer les tags."
        return 1
    fi

    cd "$REPO_DIR" || return 1

    # Récupère la dernière version via Git tags
    git fetch --tags origin >/dev/null 2>&1
    latest_version=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')

    if [[ -z "$latest_version" ]]; then
        printf "%s\n" "Aucun tag trouvé sur le dépôt. Impossible de déterminer la dernière version."
        return 1
    fi

    printf "%s\n" "Dernière version disponible : $latest_version"

    # Comparaison avec la version locale
    if [[ "$latest_version" != "${numeric[version]}" ]]; then
        printf "%s\n" "Nouvelle version détectée ! Mise à jour en cours..."
        
        # Pull depuis Git
        git pull origin main >/dev/null 2>&1 || {
            printf "%s\n" "Erreur lors de la mise à jour depuis Git."
            return 1
        }

        # Mise à jour du fichier de configuration
        build_date=$(date '+%Y-%m-%d %H:%M:%S')
        check_date=$(date '+%Y-%m-%d %H:%M:%S')

        sed -i "s|numeric\[\"version\"\]=\"[^\"]*\"|numeric[\"version\"]=\"$latest_version\"|" "$conf_file"
        sed -i "s|numeric\[\"build\"\]=\"[^\"]*\"|numeric[\"build\"]=\"$build_date\"|" "$conf_file"
        sed -i "s|numeric\[\"check\"\]=\"[^\"]*\"|numeric[\"check\"]=\"$check_date\"|" "$conf_file"

        printf "%s\n" "Mise à jour terminée vers la version $latest_version."
        
        # Relancer le programme si autoupdate est activé
        if [[ "${numeric[autoupdate]}" -eq 1 ]]; then
            printf "%s\n" "Relancement automatique du programme..."
            exec bash "$0"
        fi
    else
        printf "%s\n" "Le programme est déjà à jour (version ${numeric[version]})."
        # Met à jour juste la date de vérification
        check_date=$(date '+%Y-%m-%d %H:%M:%S')
        sed -i "s|numeric\[\"check\"\]=\"[^\"]*\"|numeric[\"check\"]=\"$check_date\"|" "$conf_file"
    fi
}

# Option 5
install() {
    # Contrôle si installation déjà faite
    
    [[ -d "$HOME/Service-Overtchat" ]] && {
        printf "%s\n" "Service-Overtchat déjà installé. Veuillez désinstaller avant de réinstaller."; return 1
    }

    printf "%s\n" "L'installation va commencer. Veuillez suivre les instructions à l'écran."
    prompt_continue

    # Affichage du message d'installation
    mess_install
    
    if ! prompt_yn "Confirmez-vous le lancement de l'installation ? (Y/N) : "; then
        printf "%s\n" "Installation annulée par l'utilisateur."
        exit 0
    fi

    # Depot GitHub
    APP_DIR="$HOME/Overtchat"
    REPO_URL="https://github.com/servus033-cloud/Overtchat.git"
    BRANCH="main"

    if ! command -v git &>/dev/null; then
        printf "%s\n" "Git n'est pas installé. Impossible d'installer."
        exit 1
    fi

    printf "%s\n" "Installation [ en cours... ]"

    # Si pas encore installé
    if [[ ! -d "$APP_DIR/.git" ]]; then
        printf "%s\n" "Clonage du dépôt..."
        git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR" || exit 1

        # Donner accès direct aux dossiers
        # (ils sont déjà dans le dépôt, donc rien à déplacer)

        # Rendre les .sh exécutables
        find "$APP_DIR/Service-Overtchat/Lib" -type f -name "*.sh" -exec chmod +x {} \;

        printf "%s\n" "Installation [ terminée ]"

        # Run setup
        bash "$APP_DIR/Service-Overtchat/Lib/setup-overtchat.sh"
        exit 0
    fi
}

# Option 6
uninstall() {
    conf[over]=$(find "$HOME" -type d -name "Service-Overtchat" -print -quit 2>/dev/null)
    if [[ -z "${conf[over]}" ]]; then
        printf "%s\n" "Service-Overtchat non installé. Rien à désinstaller."
        exit 0
    fi

    printf "%s\n" "Attention : Cette action supprimera entièrement Service-Overtchat et toutes ses données associées."
    if ! prompt_yn "Confirmez-vous la désinstallation complète ? (Y/N) : "; then
        printf "%s\n" "Annulation de la désinstallation"
        exit 0
    fi

    rm -rf "${conf[over]}" "/tmp/log~overtchat.dat" "/tmp/.egg.tmp" "/tmp/.OVER-unix"
    printf "%s\n" "Service-Overtchat a été désinstallé avec succès"
}

# Option 7
setup_sql() {
    conf[over]=$(find "$HOME/${folders[dir_lib]}" -type f -name "$(basename -- "${shell[build_sql]}")" -print -quit 2>/dev/null)
    if [[ -z "${conf[over]}" ]]; then
        printf "%s\n" "Fichier ${shell[build_sql]} introuvable. Veuillez installer le programme d'abord."
        exit 1
    fi
    bash "${conf[over]}"
}

                                        ##########################
                                        # === Menu principal === #
                                        ##########################

[[ ! -f "/tmp/.install_overtchat" ]] && {
    printf "%s\n\n" "Installation non détectée. Veuillez installer le programme."
cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
PANEL
}

[[ -f "/tmp/.install_overtchat" ]] && $(cat /tmp/.install_overtchat | grep -q "install_complete=1") && [[ ! -d "$HOME/Service-Overtchat" ]] && {
    rm -f "/tmp/.install_overtchat"
    printf "%s\n" "Installation incomplète détectée. Re-initialisation de l'install."
    bash $0
    exit 0
}

[[ -f "/tmp/.install_overtchat" ]] && $(cat "/tmp/.install_overtchat" | grep -q "install_complete=0") && {
cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
        6) Désinstaller le programme entièrement : Action irréversible
PANEL
}

[[ -d "$HOME/Service-Overtchat" ]] && [[ -f "/tmp/.install_overtchat" ]] && $(cat "/tmp/.install_overtchat" | grep -q "install_complete=1") && {
    printf "%s\n" "Installation détectée. Accès au panel complet."
    
    [[ $(find "$HOME/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null) ]] && {
        # shellcheck source=../Conf/overtchat.conf
        source "$HOME/Service-Overtchat/Conf/overtchat.conf"
    }

cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────

Veuillez faire vôtre choix :

        0) Quitter le programme : Quitter le panel et revenir au terminal
        1) Voir les logs du système : Affiche le contenu du fichier de log Systême Service-Overtchat et les logs des autres Services
        2) Info / Ajouter / Supprimer un User > : Agit à la base de données MariaDB < Hors panel actuel >
        3) Vérifier les mises à jour : Fait via GitHub si disponible
        4) Activer/Désactiver mises à jour : Active ou désactive la gestion automatique des mises à jour
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
        6) Désinstaller le programme entièrement : Action irréversible
        7) Installation/Paramètre MariaDB : Lance le script de configuration de la base de données MariaDB

PANEL
}

panels_loop() {
    local choice
    while true; do
        read -rp "Entrez votre choix (0-7) : " choice
        case "$choice" in
        0)
            printf "%s\n" "Quitter le programme. À bientôt !"
            exit 0
            ;;
        1)
            view_logs
            prompt_continue
            ;;
        2)
            funct_user
            prompt_continue
            ;;
        3)
            updates
            prompt_continue
            ;;
        4)
            upgrade
            prompt_continue
            ;;
        5)
            install
            prompt_continue
            ;;
        6)
            uninstall
            prompt_continue
            ;;
        7)
            setup_sql
            prompt_continue
            ;;
        *)
            printf "%s\n" "Choix invalide. Veuillez réessayer."
            ;;
        esac
    done
}

panels_loop "@"