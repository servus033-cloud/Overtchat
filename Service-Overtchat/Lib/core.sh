#!/bin/bash

# Localise le script, indépendamment d'où on l'appelle
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
load_conf="$SCRIPT_DIR/../Conf/overtchat.conf"

if [ -f "$load_conf" ]; then
    # shellcheck disable=SC1090
    source "$load_conf"
else
    printf "%s\n" "Chargement du fichier 'overtchat.conf' érroné : $load_conf"
    exit 1
fi

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

# ------------------------------- #

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
    "mailutils" "libssl-dev" "libreadline-dev" "libncurses5-dev"
    "gcc" "make" "sed" "awk" "grep" "tr" "chmod" "touch" "rm" "mv"
    "cp" "hostname" "date" "msmtp"
)

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
    if [[ -n "${files[logs]:-}" && -f "${files[logs]}" ]]; then
        valid "Installation terminée. Voir le fichier de log : ${files[logs]}"
    fi
    echo
}

# Exécution
check_packages "$@"

# ------------------------------- #

# Fonction client : build + hash + envoi
send_install_report() {
    [[ ! -d "$HOME/Service-Overtchat/Build" ]] && mkdir -p "$HOME/Service-Overtchat/Build"
    local USER_EMAIL="$1"     # optionnel, email de l'utilisateur (consent)
    local INSTALL_STATUS="$2" # "ok" ou "error"
    local LOGFILE="${LOGFILE:-${files[logs]}}"
    local SCRIPT_VERSION="${SCRIPT_VERSION:-v1.0}"
    local REPORT_TO=""
    local FROM=""

    # Défensif : si l'associative array 'over' existe et contient les clés, on les utilise,
    # sinon on prend des variables de repli (over_admin_mail / over_support_mail) ou on laisse vide.
    if [[ -v over[admin_mail] ]]; then
        REPORT_TO="${over[admin_mail]}"
    elif [[ -n "${over_admin_mail:-}" ]]; then
        REPORT_TO="${over_admin_mail}"
    fi

    if [[ -v over[support_mail] ]]; then
        FROM="${over[support_mail]}"
    elif [[ -n "${over_support_mail:-}" ]]; then
        FROM="${over_support_mail}"
    fi

    generate_password_safe() {
        local length=${1:-20}
        LC_ALL=C tr -dc 'A-Za-z0-9!@#$%&*()-_=+[]{}:;,.?/' </dev/urandom | head -c "$length"
        echo
    }

    # Génération mot de passe et hashage (si créer un compte)
    local user_pass hash_pass
    user_pass="$(generate_password_safe 20)"
    # stocke/hash localement, ne jamais l'envoyer en clair
    hash_pass="$(printf '%s' "$user_pass" | sha256sum | awk '{print $1}')"

    # Sauvegarde locale (si besoin) : stocker le hash, pas le mot de passe
    printf "%s\n" "$hash_pass" >>"${HOME}/Service-Overtchat/Build/.overtchat_pass_hashes"
    chmod 600 "${HOME}/Service-Overtchat/Build/.overtchat_pass_hashes"

    # Extrait les dernières lignes de log pour le rapport
    local log_excerpt
    if [[ -f "$LOGFILE" ]]; then
        log_excerpt="$(tail -n 200 "$LOGFILE" | sed 's/^/    /')"
    else
        log_excerpt="(no log file found)"
    fi

    # Récupération IP publique (silencieuse)
    local public_ip
    public_ip="$(curl -fs --max-time 3 https://ifconfig.co 2>/dev/null || echo 'unknown')"

    # Compose le rapport dans un temp file
    local tmpfile
    tmpfile="$(mktemp)" || return 1
    {
        printf "From: %s\n" "$FROM"
        printf "To: %s\n" "$REPORT_TO"
        printf "Subject: Rapport d'installation — %s — %s\n" "$(hostname)" "$(date -Iseconds)"
        printf "MIME-Version: 1.0\n"
        printf "Content-Type: text/plain; charset=UTF-8\n\n"

        printf "Hostname: %s\n" "$(hostname)"
        printf "Public-IP: %s\n" "$public_ip"
        printf "Script-Version: %s\n" "$SCRIPT_VERSION"
        printf "Status: %s\n" "$INSTALL_STATUS"
        printf "User-Hash: %s\n" "$hash_pass"
        [[ -n "$USER_EMAIL" ]] && printf "User-Email: %s\n" "$USER_EMAIL"
        printf "\n--- Logs (dernieres lignes) ---\n%s\n" "$log_excerpt"
    } >"$tmpfile"

    # Envoi via msmtp (configuration /etc/msmtprc ou ~/.msmtprc attendue)
    if command -v msmtp &>/dev/null; then
        msmtp --read-envelope-from --read-recipients <"$tmpfile"
        local rc=$?
        rm -f "$tmpfile"
        return $rc
    else
        rm -f "$tmpfile"
        echo "msmtp non installé" >&2
        return 2
    fi
}

# ------------------------------- #

generate_password_safe() {
    local length=${1:-16}
    local symbols=${2:-no}

    if ! [[ "$length" =~ ^[0-9]+$ ]] || ((length <= 0)); then
        printf "Invalid length\n" >&2
        return 1
    fi

    if command -v openssl >/dev/null 2>&1; then
        # openssl est souvent disponible et sûr
        local bytes=$(((length * 3 + 3) / 4))
        if [[ "$symbols" == "yes" ]]; then
            # on accepte le base64 filtré, puis on ajoute quelques symboles forcés
            pw="$(openssl rand -base64 "$bytes" | tr -d '/+=' | cut -c1-"$length")"
            # s'assurer d'avoir au moins un symbole
            pw="${pw:0:$((length - 1))}!" # remplace la dernière par '!' — simple mais efficace
            printf "%s\n" "$pw"
        else
            openssl rand -base64 "$bytes" | tr -d '/+=' | cut -c1-"$length" && echo
        fi
    else
        # fallback vers /dev/urandom
        if [[ "$symbols" == "yes" ]]; then
            LC_ALL=C tr -dc 'A-Za-z0-9!@#$%&*()-_=+[]{}:;,./?' </dev/urandom | head -c "$length"
        else
            LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
        fi
        echo
    fi
}
