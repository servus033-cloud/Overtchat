#!/bin/bash

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

    conf[log]=$(find "$HOME/Service-Overtchat/Logs" -type f -name "$logfile" -print -quit 2>/dev/null)
    if [[ -n "${conf[log]}" ]]; then
        logfiles="$HOME/Service-Overtchat/Logs/$logfile"
    else
        logfiles="/tmp/.Overtchat/Service-Overtchat/Logs/$logfile"
    fi

    txt="[$timestamp] $msg"
    printf '%s\n' '$txt' >>"$logfiles"
}

load_config() {
    local conf_path
    conf_path=$(find "$HOME/Service-Overtchat/Conf" \
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

    if find "$HOME/Overtchat/Service-Overtchat/Logs" -type f -name "$logfile" -print -quit 2>/dev/null; then
        logfile="$HOME/Overtchat/Service-Overtchat/Logs/$logfile"
    else
        logfile="/tmp/log~overtchat.dat"
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
    # Mise à jour Git #

    # 1) Dossier principal
    APP_DIR="$HOME/Service-Overtchat"

    if [[ -d "$APP_DIR/.git" ]]; then
        printf "%s\n" "Répertoire Git trouvé dans $APP_DIR."
    else
        printf "%s\n" "Répertoire Git introuvable dans $APP_DIR. Recherche secondaire..."

        # 2) Dossier de secours
        local fallback="/tmp/.Overtchat"

        if [[ -d "$fallback/.git" ]]; then
            printf "%s\n" "Répertoire Git trouvé dans $fallback. Utilisation de ce dépôt pour les mises à jour."
            APP_DIR="$fallback"
        else
            printf "%s\n" "Répertoire Git introuvable dans $APP_DIR et $fallback. Impossible de vérifier les mises à jour."
            return 1
        fi
    fi

    # Sélection de la branche
    BRANCH="main"

    # Aller dans le dépôt sélectionné
    cd "$APP_DIR" || { 
        echo "Erreur chargement $APP_DIR"
        return 1
    }

    git fetch origin "$BRANCH"
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH)

    if [[ "$LOCAL" != "$REMOTE" ]]; then
        printf "%s\n" "Une nouvelle version a été détectée !"
        if prompt_yn "Voulez-vous mettre à jour maintenant ? (Y/N) : "; then
            upgrade
        else
            printf "%s\n" "Mise à jour annulée par l'utilisateur."
        fi
    else
        printf "%s\n" "Déjà à jour."
    fi
}

# Option 4
upgrade() {
    # Chargement config
    if ! load_config; then
        return 1
    fi

    printf "%s\n" "Version actuelle : ${numeric[version]}, mise à jour automatique : ${numeric[autoupdate]}"

    # Aller dans APP_DIR
    cd "$APP_DIR" || { 
        echo "Erreur chargement $APP_DIR"
        return 1
    }

    # Fichier config (défini UNE SEULE FOIS)
    conf_file="$APP_DIR/Conf/overtchat.conf"

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
        check_date="$build_date"

        sed -i "s|numeric\[\"version\"\]=\"[^\"]*\"|numeric[\"version\"]=\"$latest_version\"|" "$conf_file"
        sed -i "s|numeric\[\"build\"\]=\"[^\"]*\"|numeric[\"build\"]=\"$build_date\"|" "$conf_file"
        sed -i "s|numeric\[\"check\"\]=\"[^\"]*\"|numeric[\"check\"]=\"$check_date\"|" "$conf_file"

        printf "%s\n" "Mise à jour terminée vers la version $latest_version."
        
        # Relancement si autoupdate actif
        if [[ "${numeric[autoupdate]}" -eq 1 ]]; then
            printf "%s\n" "Relancement automatique du programme..."
            exec "$APP_DIR/bin/Lib/$0"
        fi
    else
        printf "%s\n" "Le programme est déjà à jour (version ${numeric[version]})."
        check_date=$(date '+%Y-%m-%d %H:%M:%S')
        sed -i "s|numeric\[\"check\"\]=\"[^\"]*\"|numeric[\"check\"]=\"$check_date\"|" "$conf_file"
    fi
}

# Option 5
install() {
    # Contrôle si installation déjà faite
    if [[ -d "$HOME/Overtchat" ]] || [[ -d "$HOME/Overtchat/Service-Overtchat" ]]; then
        printf "%s\n" "Service déjà installé"
        return 1
    fi

    printf "%s\n" "L'installation va commencer. Veuillez suivre les instructions à l'écran."
    prompt_continue

    # Affichage du message d'installation
    mess_install

    if ! prompt_yn "Confirmez-vous le lancement de l'installation ? (Y/N) : "; then
        printf "%s\n" "Installation annulée par l'utilisateur."
        exit 0
    fi

    APP_DIR="/tmp/.Overtchat"
    REPO_URL="https://github.com/servus033-cloud/Overtchat.git"
    BRANCH="main"
    MAKEVAR="release"

    if ! command -v git &>/dev/null; then
        printf "%s\n" "Git n'est pas installé. Impossible d'installer. Veuillez installer Git via : sudo apt install git"
        exit 1
    fi

    printf "%s\n" "Installation [ en cours... ]"

    # Si pas encore installé
    if [[ ! -d "$APP_DIR/.git" ]]; then
        printf "%s\n" "Clonage du dépôt..."
        git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR" || { printf "%s\n" "Erreur lors du clonage"; exit 1; }

        # Rendre les scripts exécutables
        for dir in "$APP_DIR/Install/bin" "$APP_DIR/Service-Overtchat/Lib"; do
            if [[ -d "$dir" ]]; then
                search=$(find "$dir" -type f -name "*.sh" -print -quit 2>/dev/null)
                if [[ "$search" ]]; then
                    printf "%s\n" "Scripts .sh trouvés dans $dir"
                    find "$dir" -type f -name "*.sh" -exec chmod +x {} \;
                else
                    printf "%s\n" "Aucun script .sh trouvé dans $dir. Installation impossible."
                    exit 1
                fi
            fi
        done

        # Compilation
        cd "$APP_DIR/Install/" || exit 1
        makefile="$APP_DIR/Install/MAKEFILE"
        if [[ -f "$makefile" ]]; then
            printf "%s\n" "Lancement de la compilation..."
            make -f "$makefile" "$MAKEVAR" || { printf "%s\n" "Erreur lors de la compilation"; exit 1; }
            printf "%s\n" "Compilation terminée avec succès."

            if [[ -f "$HOME/Service-Overtchat.tar.gz" ]]; then
                printf "%s\n" "Déploiement de l'archive..."
                tar -xzf "$HOME/Service-Overtchat.tar.gz" -C "$HOME/" || { printf "%s\n" "Erreur lors du déploiement"; exit 1; }
                printf "%s\n" "Déploiement terminé avec succès."
                rm -f "$HOME/Service-Overtchat.tar.gz"
                printf "%s\n" "Installation terminée avec succès."
                
                mkdir $HOME/Service-Overtchat/tmp || exit 1
                cd $HOME/Service-Overtchat/bin/Lib || exit 1
                rm -f $HOME/$0
                ./setup-overtchat
            else
                printf "%s\n" "Archive introuvable après compilation. Installation annulée."
                exit 1
            fi
        else
            printf "%s\n" "Fichier MAKEFILE introuvable. Impossible de compiler."
            exit 1
        fi
        exit 0
    fi
}

# Option 6
uninstall() {
    APP_DIR="$HOME/Service-Overtchat"
    APP_GIT="/tmp/.Overtchat"

    printf "%s\n" "Attention : Cette action supprimera entièrement Service-Overtchat et toutes ses données associées."
     if ! prompt_yn "Confirmez-vous la désinstallation complète ? (Y/N) : "; then
        printf "%s\n" "Annulation de la désinstallation"
        exit 0
    fi

    if [[ -d "$APP_DIR" ]]; then
        printf "%s\n" "Désinstallation du Programme"
        for dir in $APP_DIR; do
            if [[ -f "$dir" ]]; then
                printf "%s\n" "Suppression du fichier $dir"
                rm -f "$dir"
            fi
            if [[ -d "$dir" ]]; then
                printf "%s\n" "Suppression du dossier $dir"
                rm -r "$dir"
            fi
        done
    fi

    if [[ -d "$APP_GIT" ]]; then
        printf "%s\n" "Désinstallation du Programme"
        for dir in $APP_GIT; do
            if [[ -f "$dir" ]]; then
                printf "%s\n" "Suppression du fichier $dir"
                rm -f "$dir"
            fi
            if [[ -d "$dir" ]]; then
                printf "%s\n" "Suppression du dossier $dir"
                rm -r "$dir"
            fi
        done
    fi

    printf "%s\n" "Service-Overtchat a été désinstallé avec succès"
    printf "%s\n" "Merci d'avoir utilisé Service-Overtchat by SerVuS"
    printf "%s\n" "Pour nous retrouver : http://service.overtchat.free.fr"
    exit 0
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

# Option 8
init_git() {
    printf "%s\n" "Initialisation du dépôt Git..."
    APP_DIR="/tmp/.Overtchat"
    REPO_URL="https://github.com/servus033-cloud/Overtchat.git"
    BRANCH="main"
    if [[ -d "$APP_DIR" ]]; then
        rm -rf "$APP_DIR"
    fi
    git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR" || { printf "%s\n" "Erreur lors du clonage"; exit 1; }
    printf "%s\n" "Dépôt Git initialisé avec succès."
}

#!/usr/bin/env bash

cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────
PANEL

INSTALL_TMP="/tmp/.Overtchat"
INSTALL_HOME="$HOME/Service-Overtchat"

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
            continue
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
        8)
            init_git
            prompt_continue
            ;;
        *)
            printf "%s\n" "Choix invalide. Veuillez réessayer."
            ;;
        esac
    done
}

panels_loop "@"