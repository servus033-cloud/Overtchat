#!/usr/bin/env bash

# overtchat-setup : Script d'installation d'Overtchat
# Auteur : Gauthier
# Date : 2024-06-15
# Version : 1.0.0
# Licence : MIT
# script controle packages

set -euo pipefail
IFS=$'\n\t'

debug=0

# Gestion Packages
REQUIRED_PACKAGES=(
    "curl" "wget" "git" "bash" "sed" "awk" "grep" "chmod" "mkdir" "find" "cat"
    "mariadb-client" "php" "php-mysql" "apache2" "libapache2-mod-php" "php-cli"
    "php-curl" "php-xml" "php-mbstring" "php-zip" "php-gd" "php-intl" "php-bcmath"
    "php-imagick" "mailutils" "dovecot-core" "dovecot-imapd" "dovecot-pop3d"
    "postfix" "php-mail" "php-pear" "php-mail-mime" "php-net-smtp" "php-net-socket"
    "phpmyadmin" "mariadb-server" "openssl" "ufw" "certbot" "python3-certbot-apache"
    "build-essential" "libssl-dev" "libffi-dev" "python3-dev" "python3-pip"
    "virtualenv" "tclsh" "expect" "tcl-dev" "python3-tk" "cron" "openssl" "pwgen" "cut"
    "mailutils" "libssl-dev" "libreadline-dev" "libncurses-dev"
    "gcc" "make" "sed" "awk" "grep" "tr" "chmod" "touch" "rm" "mv"
    "cp" "hostname" "date" "msmtp"
)

std() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}
warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}
error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}
valid() {
    echo -e "\033[1;32m[OK]\033[0m $1"
}

cat << 'EOF'
                    ===========================================================
                            Overtchat Installer Bootstrapper
                    ===========================================================
                    Ce script télécharge et lance l'installateur d'Overtchat.
                    Nous allons vérifier et installer les dépendances minimales.
                            Un acces root (sudo) peut être requis.
                    ===========================================================
EOF

check_packages() {
    local fast_mode=0
    local update_stamp="/tmp/.overtchat_apt_timestamp"
    local update_ttl=$((6 * 3600)) # 6 heures

    [[ -v 1 && "$1" == "--fast" ]] && fast_mode=1

    warn "Vérification des paquets requis pour Service-Overtchat..."
    local missing_packages=()
    local installed_packages=()

    if ! command -v apt-get &>/dev/null; then
        error "APT n'est pas disponible sur ce système (non compatible)."
        return 1
    fi

    # Nettoyage des doublons pour éviter les répétitions inutiles
    mapfile -t REQUIRED_PACKAGES < <(printf "%s\n" "${REQUIRED_PACKAGES[@]}" | awk '!seen[$0]++')

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if command -v "$pkg" &>/dev/null; then
            installed_packages+=("$pkg")
        elif dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
            installed_packages+=("$pkg")
        else
            missing_packages+=("$pkg")
        fi
    done

    valid "${#installed_packages[@]} paquets déjà installés"
    [[ ${#missing_packages[@]} -gt 0 ]] && warn "${#missing_packages[@]} paquets manquants"

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        valid "Tous les paquets requis sont déjà présents."
    fi

    if [[ $fast_mode -eq 1 ]]; then
        if [[ -f "$update_stamp" ]]; then
            local last_update
            last_update=$(stat -c %Y "$update_stamp" 2>/dev/null || echo 0)
            local now
            now=$(date +%s)
            if ((now - last_update < update_ttl)); then
                warn "Mode rapide activé : mise à jour APT ignorée (moins de 6h)."
            else
                valid "Cache expiré, exécution d’un apt-get update..."
                sudo apt-get update -qq && touch "$update_stamp"
            fi
        else
            valid "Première exécution du mode rapide, mise à jour initiale..."
            sudo apt-get update -qq && touch "$update_stamp"
        fi
    else
        valid "Mise à jour complète de la liste des paquets..."
        sudo apt-get update -qq && touch "$update_stamp"
    fi

    local available_packages=()
    for pkg in "${missing_packages[@]}"; do
        if apt-cache show "$pkg" &>/dev/null; then
            available_packages+=("$pkg")
        else
            warn "Paquet inexistant dans les dépôts : $pkg (ignoré)"
        fi
    done

    if [[ ${#available_packages[@]} -eq 0 ]]; then
        valid "Aucun des paquets manquants n’est disponible dans les dépôts."
    else
        warn "Installation de ${#available_packages[@]} paquet(s)..."
        if ! sudo apt-get install -y --no-install-recommends "${available_packages[@]}"; then
            error "Échec de l’installation de certains paquets."
            sudo apt-get install -f -y
        fi
    fi

    valid "Nettoyage des paquets inutiles..."
    sudo apt-get autoremove -y >/dev/null
    sudo apt-get autoclean -y >/dev/null
    sudo dpkg --configure -a >/dev/null

    if sudo apt-get check -qq; then
        valid "Tous les paquets sont fonctionnels et sans conflit."
    else
        error "Des dépendances cassées détectées, tentative de réparation..."
        sudo apt-get install -f -y
    fi

    std "Installation des paquets terminée"
    return 0
}

# Exécution
check_packages "$@" || return 1

if [[ $? -ne 0 ]]; then
    error "Échec de la vérification/installation des paquets requis."
    exit 1
else
    std "Toutes les dépendances requises sont installées."
    : $((debug++))
fi