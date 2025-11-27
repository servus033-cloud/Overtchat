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

# safe_assoc_get : récupère la valeur d'un assoc array sans provoquer d'erreur set -u
safe_assoc_get() {
    # exemple: val=$(safe_assoc_get "files" "logs")
    local arr_name="$1" key="$2" out=""
    # évalue de façon indirecte et protégée
    eval '[[ -n ${'"$arr_name"'['"$key"']+_} ]] && out=${'"$arr_name"'['"$key"']} || out=""'
    printf "%s\n" "$out"
}

# control_order : vérifie l'existence d'une clé dans un tableau assoc, renvoie 0 si ok
control_order() {
    # exemple: control_order "files" "logs" "Défaut variable" "049"
    [[ ! $# -ge 2 ]] && {
        printf "%s\n" "control_order: Nombre d'arguments insuffisant"
        return 1
    }

    [[ ! $# -le 4 ]] && {
        printf "%s\n" "control_order: Nombre d'arguments trop élevé"
        return 1
    }

    [[ ! "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && {
        printf "%s\n" "control_order: Nom de tableau invalide"
        return 1
    }

    [[ ! "$2" =~ ^[a-zA-Z0-9_]+$ ]] && {
        printf "%s\n" "control_order: Clé invalide"
        return 1
    }

    [[ ! -z "${3:-}" ]] && [[ ! -z "${4:-}" ]] && {
        if ! [[ "$4" =~ ^[0-9]{3}$ ]]; then
            printf "%s\n" "control_order: Code erreur invalide"
            return 1
        fi
    }

    [[ -z "${3:-}" ]] && [[ ! -z "${4:-}" ]] && {
        printf "%s\n" "control_order: Message d'erreur manquant"
        return 1
    }

    [[ -z "${4:-}" ]] && [[ ! -z "${3:-}" ]] && {
        printf "%s\n" "control_order: Code erreur manquant"
        return 1
    }

    [[ ! "$(declare -p "$1" 2>/dev/null | grep 'declare -A')" ]] && {
        printf "%s\n" "Tableau associatif '$1' introuvable"
        return 1
    }

    [[ -z "$(eval "printf '%s\n' \"\${!$1[@]}\" | grep -w '^$2$'")" ]] && {
        local msg="${3:-Variable manquante}" code="${4:-000}"
        printf "%s\n" "$msg" "$code"
        return 1
    }

    # On controle si le fichier source overtchat.conf est bien present pour prendre les variable et le charger
    [[ "$(declare -p files 2>/dev/null | grep 'declare -A')" ]] || {
        printf "%s\n" "Tableau associatif 'files' introuvable"
        return 1
    }
   
    [[ -v files[conf] ]] || {
        printf "%s\n" "Clé 'conf' introuvable dans le tableau 'files'"
        return 1
    }

    if ! source "${files[conf]}" 2>/dev/null; then
        printf "%s\n" "Impossible de charger le fichier de configuration : ${files[conf]}"
        return 1
    fi
    return 0
}

                                        # ────────────────────────────── #
                                        #   Gestion de la variable Log
                                        # ────────────────────────────── #

log() {
    local msg="$1"
    local timestamp logfile txt
    timestamp="$(date "+%Y-%m-%d %H:%M:%S")"
    logfile="/tmp/log~overtchat.dat"

    txt="[$timestamp] $msg"
    printf '%s\n' '$txt' >>"$logfile"
}

                                        # ────────────────────────────── #
                                        #   Lancement des fonctions
                                        # ────────────────────────────── # 


#################################
# === Installation Générale === #
#################################

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
show_logs() {
    # Vérifie proprement que files[logs] existe
    if ! control_order "files" "logs" "Défaut variable Erreur :" "049"; then
        return 1
    fi

    # valeur récupérée de façon sûre
    local relpath logfile
    relpath="$(safe_assoc_get "files" "logs")"
    # si la valeur est vide (malgré control_order) on arrête
    if [[ -z "$relpath" ]]; then
        printf "%s\n" "Chemin de logs vide (Code erreur : 049)"
    fi

    # construire chemin absolu sûr
    if [[ "$relpath" == /* ]]; then
        logfile="$relpath"
    else
        logfile="$HOME/$relpath"
    fi

    # assure le dossier parent
    mkdir -p "$(dirname "$logfile")"
    [[ -f "$logfile" ]] || touch "$logfile"

    printf "%s\n" "Contenu du fichier de logs : $logfile"

    # basculer les logs temporaires
    if [[ -f "/tmp/log~overtchat.dat" ]]; then
        cat "/tmp/log~overtchat.dat" >>"$logfile"
    fi

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
    if ! control_order "folders" "dir_lib" "Défaut variable Code" "049"; then
        return 1
    fi

    # On controle si dossier principale existe
    [[ ! -d "${folders[dir_lib]}" ]] && {
        printf "%s\n" "Dossier ${folders[dir_lib]} introuvable. Veuillez installer le programme d'abord."
        return 1
    }

    # valeur récupérée de façon sûre
    local libdir
    libdir="$(safe_assoc_get "folders" "dir_lib")"

    # si la valeur est vide (malgré control_order) on arrête
    if [[ -z "$libdir" ]]; then
        printf "%s\n" "Chemin du dossier Lib vide (Code erreur : 049)"
        return 1
    fi

    # On source le fichier user.sh
    if [[ -f "$HOME/$libdir/user.sh" ]]; then
        # shellcheck source=../Lib/user.sh
        bash "$HOME/$libdir/user.sh"
    else
        printf "%s\n" "Fichier user.sh introuvable dans $HOME/$libdir. Veuillez installer le programme d'abord."
        return 1
    fi
    # On execute la fonction user_panel
    # user_panel
}

# Option 3
check_updates() {
    [[ ! -f "/tmp/.install_overtchat" ]] && {
        printf "%s\n" "Installation non détectée. Veuillez installer le programme d'abord."
        return 1
    }

    cat /tmp/.install_overtchat | grep -q "install_complete=1" || {
        printf "%s\n" "Installation incomplète. Veuillez terminer l'installation avant de modifier les mises à jour."
        return 1
    }

    # On regarde si le dossier Service-Overtchat existe
    [[ ! -d "$HOME/Service-Overtchat" ]] && {
        printf "%s\n" "Erreur : Dossier Service-Overtchat introuvable. Veuillez réinstaller le programme."
        return 1
    }

    # On regarde si le fichier overtchat.conf existe
    if [[ ! $(find "$HOME/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null) ]]; then
        printf "%s\n" "Erreur : Fichier de configuration introuvable. Veuillez réinstaller le programme."
        return 1
    fi

    # On regarde si les declare sont chargés
    if [[ $(compgen -A files &>/dev/null) ]]; then
        :
    else
        # On source le fichier overtchat.conf
        # shellcheck source=../Conf/overtchat.conf
        source "$HOME/Service-Overtchat/Conf/overtchat.conf"
    fi

    if ! control_order "files" "conf" "Défaut variable Code" "049"; then
        return 1
    fi
    
    # Depot GITHub
    APP_DIR="$HOME/Service-Overtchat"
    REPO_URL="https://github.com/servus033-cloud/Overtchat/Overtchat.git"
    BRANCH="main" # ou master selon ton dépôt

    # Vérifier si Git est installé
    if ! command -v git &>/dev/null; then
        echo "Git n'est pas installé. Impossible de mettre à jour."
        exit 1
    fi

    cd "$APP_DIR" || {
        echo "Impossible d'accéder au dossier $APP_DIR"
        exit 1
    }

    # Vérifier les mises à jour
    git fetch origin $BRANCH
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/$BRANCH)

    if [[ "$LOCAL" != "$REMOTE" ]]; then
        echo "Nouvelle version détectée ! Mise à jour en cours..."
        git pull origin $BRANCH
        echo "Mise à jour terminée."

        # Optionnel : relancer le programme
        # pkill -f "nom_du_programme"
        # ./start.sh
    else
        echo "Le programme est déjà à jour."
        cd $HOME
    fi
}

# Option 4
maj_updates() {
    [[ ! -f "/tmp/.install_overtchat" ]] && {
        printf "%s\n" "Installation non détectée. Veuillez installer le programme d'abord."
        return 1
    }

    cat /tmp/.install_overtchat | grep -q "install_complete=1" || {
        printf "%s\n" "Installation incomplète. Veuillez terminer l'installation avant de modifier les mises à jour."
        return 1
    }
    
    if ! control_order "numeric" "update" "Défaut variable Code" "049"; then
        return 1
    fi
    case "${numeric[update]}" in
    0)  
        sed -i 's/numeric\[update\]=1/numeric[update]=0/' "${files[conf]}"
        log "Mises à jour désactivées."
        ;;
    1)
        sed -i 's/numeric\[update\]=0/numeric[update]=1/' "${files[conf]}"
        log "Mises à jour activées."
        ;;
    *)
        printf "%s\n" "Valeur numeric[update] invalide erreur : null"
        return 1
        ;;
    esac
}

# Option 5
install() {
    # Contrôle si installation déjà faite
    
    [[ -d "$HOME/Service-Overtchat" ]] && {
        printf "%s\n" "Service-Overtchat déjà installé. Veuillez désinstaller avant de réinstaller."; return 1
    }

    [[ -f "/tmp/.install_overtchat" ]] && {
        cat /tmp/.install_overtchat | grep -q "install_complete=1" && {
            printf "%s\n" "Installation déjà complète. Veuillez désinstaller avant de réinstaller."
            return 1
        }
    }
    printf "%s\n" "L'installation va commencer. Veuillez suivre les instructions à l'écran."
    prompt_continue

    # Affichage du message d'installation
    mess_install
    
    if ! prompt_yn "Confirmez-vous le lancement de l'installation ? (Y/N) : "; then
        printf "%s\n" "Installation annulée par l'utilisateur."
        exit 0
    fi

    # Initialisation du fichier temporaire
    >"/tmp/.install_overtchat"
    echo "install_complete=0" >>"/tmp/.install_overtchat"
    
    # Depot GITHub
    APP_DIR="$HOME"
    REPO_URL="https://github.com/servus033-cloud/Overtchat.git"
    BRANCH="main"

    # Vérifier si Git est installé
    if ! command -v git &>/dev/null; then
        printf "%s\n" "Git n'est pas installé. Impossible d'installer."
        exit 1
    fi

    printf "%s\n" "Installation [ en cours... ]"

    # Si le dossier n'est pas un dépôt Git → on clone
    if [[ ! -d "$APP_DIR/.git" ]]; then
        printf "%s\n" "Clonage du dépôt..."
        # Clone dans un dossier temporaire
        TMP_DIR=$(mktemp -d)
        git clone -b "$BRANCH" "$REPO_URL" "$TMP_DIR" || exit 1
      
        # Déplacer uniquement les dossiers voulus
        mv "$TMP_DIR/Service-Overtchat" "$APP_DIR/"
        mv "$TMP_DIR/Serveur-Overtchat" "$APP_DIR/"
      
        # Nettoyer
        rm -rf "$TMP_DIR"

        # On controle les fichier *.sh si mode +x sinon les activer
        find "$APP_DIR/Service-Overtchat/Lib/" -type f -name "*.sh" -exec chmod +x {} \;

        printf "%s\n" "Installation [ terminée ]"

        # On marque l'installation comme complète
        rm -f "/tmp/.install_overtchat"
        echo "install_complete=1" >>"/tmp/.install_overtchat"

        # On supprime l'archive et On execute le script setup-overtchat.sh dans le bon dossier pour finaliser l'installation
        rm -f $0 && bash "$APP_DIR/Service-Overtchat/Lib/setup-overtchat.sh"
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

[[ ! -f /tmp/.install_overtchat ]] && {
    printf "%s\n" "Installation non détectée. Veuillez installer le programme."
cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
PANEL
}

[[ -f /tmp/.install_overtchat ]] && $(cat /tmp/.install_overtchat | grep -q "install_complete=0") && {
cat <<'PANEL'
                        ──────────────────────────────
                        |  Service-Overtchat - Panel  |
                        ──────────────────────────────
        0) Quitter le programme : Quitter le panel et revenir au terminal
        5) Installer le programme Service-Overtchat : Lance le script d'installation complet
        6) Désinstaller le programme entièrement : Action irréversible
PANEL
}

[[ -d "$HOME/Service-Overtchat" ]] && [[ -f /tmp/.install_overtchat ]] && $(cat /tmp/.install_overtchat | grep -q "install_complete=1") && {
    printf "%s\n" "Installation détectée. Accès au panel complet."
    [[ find "$HOME/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null ]] && {
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
        2) Info / Ajouter / Supprimer un User > : Agit à la base de données MariaDB
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
            show_logs
            prompt_continue
            ;;
        2)
            funct_user
            prompt_continue
            ;;
        3)
            check_updates
            prompt_continue
            ;;
        4)
            maj_updates
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