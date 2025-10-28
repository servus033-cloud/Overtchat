#!/usr/bin/env bash
set -euo pipefail

# nettoyage de l'ecran
clear

debug=0

# Etape 1 : Logo
cat << 'LOGO'
                ##############################################
                ##	Service Overtchat New Generation    ##
                ##			V2.0		    ##
                ##############################################
                ##		Copyrigth by @SerVuS@ 	    ##
                ##    Contact : support.overtchat@free.fr   ##
                ##############################################

        Bienvenue sur le programme Service-Overtchat créer par SerVuS.

LOGO
printf "%s\n\n" "Scan en cours du programme..."
if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n\n\n" "====== Installation en cours... ======"
# Bienvenue
cat <<'GLOB'
    Nous allons procéder à l'installation de votre serveur Service-Overtchat pour le bon fonctionnement du programme.
    
    Ce script va vérifier que vous avez bien les packages nécessaires d'installés sur votre système.
    Ensuite, il va configurer les fichiers de base et les dossiers nécessaires au bon fonctionnement du service.
    Enfin, il vous proposera de configurer les paramètres essentiels tels que la base de données, le serveur web, et les options de sécurité.
    
    !!! Assurez-vous d'avoir les droits administratifs (sudo) pour exécuter ce script. !!!

    Tout sera géré automatiquement pour vous faciliter la tâche via Mariadb, Apache2 et PHP.
    Si vous ne voulez pas de gestion Mysql/Mariadb, merci de ne pas utiliser ce script et de faire une installation manuelle.

            Voulez-vous vraiment lancer l'installation du programme Service-Overtchat ?
            => Appuyez sur Entrée pour continuer... ou appuyer sur N pour quitter. <=
GLOB
    # Démarrage 
    read -r -n1 response
    if [[ "$response" =~ [Nn] ]]; then
        clear && printf "%s\n" "Installation annulée par l'utilisateur. Au revoir !"; exit 0
    fi
    mkdir -p "$HOME/Service-Overtchat"; printf "%s\n" "Création du dossier principale Service-Overtchat"
else
    printf "%s\n" "Controle : Dossier principale existant"
fi

if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Conf" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Conf > vers $HOME/Service-Overtchat ------"
    mkdir -p "$HOME/Service-Overtchat/Conf"
fi

if [[ ! "$(find "$HOME/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "Création du fichier overtchat.conf [ en cours... ]"
    sleep 1
# Création du fichier
cat > "$HOME/Service-Overtchat/Conf/overtchat.conf" <<'GLOBAL'
# ──────────────────────────────────────────
# Configuration globale - Service Overtchat
# Fichier de variables centralisées
# ──────────────────────────────────────────

# Declaration globale
declare -A over info web numeric folders files shell server prog export

# Informations sur le service
over["sendmail"]="overtchat@free.fr"
over["support_mail"]="support.${over[sendmail]}"
over["admin_mail"]="service.${over[sendmail]}"

# Licence Service-Overtchat
info["build"]="d2894715292bb1c4fd76aff10ea68f048d69fef3c891ae723cc3"
info["status"]="gratuit"
info["licence"]="Copyright © 2025 Service-Overtchat"

# Gestion Web
web["site"]="http://service.overtchat.free.fr"
web["data"]="${web[site]}/$USER/info.php"
web["sql"]="${web[site]}/$USER/data.php"

# Informations de débogage et version
numeric["version"]="2.0.1"  # Version actuelle du programme
numeric["build"]="$(date)"  # Date de compilation
numeric["check"]="$(date)"  # Date de la dernière vérification de mise à jour
numeric["update"]=0         # 0 = désactivé, 1 = activé
numeric["debug"]=1          # 0 = normal, 1 = installation érroné
numeric["limitfile"]=5M     # Taille limite des fichiers de logs
numeric["mod_folders"]=600  # Permissions des dossiers critiques
numeric["load"]=null        # Visibilité sur le chargement du fichier de configuration

# Dossiers et fichiers critiques de sécurité
folders["dir_over"]="Service-Overtchat"             # Dossier Générale
folders["dir_conf"]="${folders[dir_over]}/Conf"     # Gestion Config Programme
folders["dir_users"]="${folders[dir_over]}/Users"   # Gestion Access
folders["dir_build"]="${folders[dir_over]}/Build"   # Gestion Programme
folders["dir_logs"]="${folders[dir_over]}/Logs"     # Gestion Logs
folders["dir_lib"]="${folders[dir_over]}/Lib"       # Gestion librairies

# Gestion Compatibilité
folders["dir_unix"]="${folders[dir_build]}/Unix"    # Compatible Linux
folders["dir_win"]="${folders[dir_build]}/Windows"  # Compatible Windows

# Fichiers critiques de sécurité
files["conf"]="${folders[dir_lib]}/overtchat.conf"      # Fichier conf générale
files["logs"]="${folders[dir_logs]}/logs.dat"           # Fichier Logs générale
files["userlist"]="${folders[dir_users]}/userlist.dat"  # Gestion des Access Users
files["banlist"]="${folders[dir_users]}/banlist.dat"    # Gestion des Access User Banni

# Dossiers Lib
shell["build_core"]="${folders[dir_lib]}/core.sh"      # Compilateur Logs/Packages

# Serveur Ircd/Ircu
server["unreal"]="https://www.unrealircd.org/downloads/unrealircd-6.2.0.2.tar.gz"
server["ircu"]="https://github.com/ircd-hybrid/ircd-hybrid/archive/8.2.47.tar.gz"

# Programme
prog["eggdrop"]="http://ftp.eggheads.org/pub/eggdrop/source/1.10/eggdrop-1.10.1.tar.gz"
prog["build_irix"]="${folders[dir_unix]}/IriX"             # Programme IriX
prog["build_pooshy"]="${folders[dir_unix]}/Pooshy"         # Programme Pooshy
prog["build_overtchat"]="${folders[dir_unix]}/Overtchat"   # Programme Overtchat

# Configuration système générale
info["notice_win"]="${folders[dir_lib]}/notice_overtchat.exe" # Notice pour Windows
info["notice_unix"]="${folders[dir_lib]}/notice_overtchat.dat" # Notice pour Linux

export["source"]="$HOME/Service-Overtchat/Lib/core.sh"

# === Fonctions de base ===
std() { echo -e "\e[0m $1"; }
valid() { echo -e "\e[32m[VALIDE]\e[0m $1"; }
warn() { echo -e "\e[33m[WARNING]\e[0m $1"; } 
error() { echo -e "\e[31m[ERROR]\e[0m $1"; } 
check() { echo -e "\e[36m[CHECK]\e[0m $1"; } 

# ──────────────────────────────────────────
GLOBAL
    printf "%s\n" "Création du fichier overtchat.conf [ terminé ]"
    sleep 1
else
    printf "%s\n" "Fichier overtchat.conf [ actif ]"; debug=1
fi

if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Lib" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Lib > vers $HOME/Service-Overtchat ------"
    mkdir -p "$HOME/Service-Overtchat/Lib"
fi

if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Logs" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Logs > vers $HOME/Service-Overtchat ------"
    mkdir -p "$HOME/Service-Overtchat/Logs"
fi

if [[ ! "$(find "$HOME/Service-Overtchat/Lib" -type f -name "core.sh" -print -quit 2>/dev/null)" ]]; then
printf "%s\n" "Création du fichier core.sh [ en cours... ]"
sleep 1

cat > "$HOME/Service-Overtchat/Lib/core.sh" <<'EOF'
#!/usr/bin/env bash

load_conf=$(find "$HOME/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null)

if [[ ! -v load_conf ]]; then
    printf "%s\n" "Erreur fichier overtchat.conf"; exit 1
else
    if [[ ! -v numeric[load] ]]; then
        sed -i 's/numeric\[load\]=null/numeric[load]=1/' "$load_conf"
        source "$load_conf"
    elif [[ -v numeric[load] ]]; then
        if [[ ${numeric[load]} == "null" ]]; then
            sed -i 's/numeric\[load\]=null/numeric[load]=1/' "$load_conf"
            source "$load_conf"
        fi
    fi
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

# Fonction de log
log() {
    [[ -v files[logs] && ! -f ${files[logs]} ]] && touch ${files[logs]}
    local msg="$1"
    local timestamp logfile txt
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    if [[ -v files[logs] ]]; then
        logfile="${files[logs]}"
        txt="[$timestamp] $msg"
    fi

    echo -e "$txt" | tee -a "$logfile" >/dev/null
}

# Fonction de rotation 
rotate_log_if_needed() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0

    local limit="${numeric[limitfile]//[!0-9]/}"   # extrait la valeur numérique (5M → 5)
    local size_mb=$(( $(stat -c%s "$file") / 1024 / 1024 ))

    if (( size_mb >= limit )); then
        local timestamp
        timestamp=$(date "+%Y%m%d_%H%M%S")
        mv "$file" "${file%.*}_${timestamp}.old"
        : > "$file"
        warn "Rotation du fichier ${file##*/} ( taille: ${size_mb}M, limite: ${numeric[limitfile]} )"
    fi
}

# Contrôle global des fichiers de logs
control_logs_rotation() {
        [[ -n ${files[logs]} ]] && rotate_log_if_needed "${files[logs]}"
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
            local last_update=$(stat -c %Y "$update_stamp" 2>/dev/null || echo 0)
            local now=$(date +%s)
            if (( now - last_update < update_ttl )); then
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
    fi

    warn "Installation de ${#available_packages[@]} paquet(s)..."
    if ! sudo apt-get install -y --no-install-recommends "${available_packages[@]}"; then
        error "Échec de l’installation de certains paquets."
        sudo apt-get install -f -y
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
    [[ -f "${files[logs]}" ]] && valid "Installation terminée. Voir le fichier de log : ${files[logs]}"
    echo
}

# Exécution
check_packages "$@"

                  # ------------------------------- #

# Gestion Email
generate_password_safe() {
    local length=${1:-20}
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%&*()-_=+[]{}:;,.?/' < /dev/urandom | head -c "$length"
    echo
}

# Fonction client : build + hash + envoi
send_install_report() {
    [[ ! -d "$HOME/Service-Overtchat/Build" ]] && mkdir -p "$HOME/Service-Overtchat/Build"
    local USER_EMAIL="$1"      # optionnel, email de l'utilisateur (consent)
    local INSTALL_STATUS="$2"  # "ok" ou "error"
    local LOGFILE="${LOGFILE:-${files[logs]}}"
    local SCRIPT_VERSION="${SCRIPT_VERSION:-v1.0}"
    local REPORT_TO="${over[admin_mail]}"
    local FROM="${over[support_mail]}"

    # Génération mot de passe et hashage (si créer un compte)
    local user_pass hash_pass
    user_pass="$(generate_password_safe 20)"
    # stocke/hash localement, ne jamais l'envoyer en clair
    hash_pass="$(printf '%s' "$user_pass" | sha256sum | awk '{print $1}')"

    # Sauvegarde locale (si besoin) : stocker le hash, pas le mot de passe
    printf "%s\n" "$hash_pass" >> "${HOME}/Service-Overtchat/Build/.overtchat_pass_hashes" 
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
    } > "$tmpfile"

    # Envoi via msmtp (configuration /etc/msmtprc ou ~/.msmtprc attendue)
    if command -v msmtp &>/dev/null; then
        msmtp --read-envelope-from --read-recipients < "$tmpfile"
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

    if ! [[ "$length" =~ ^[0-9]+$ ]] || (( length <= 0 )); then
        printf "Invalid length\n" >&2
        return 1
    fi

    if command -v openssl >/dev/null 2>&1; then
        # openssl est souvent disponible et sûr
        local bytes=$(( (length * 3 + 3) / 4 ))
        if [[ "$symbols" == "yes" ]]; then
            # on accepte le base64 filtré, puis on ajoute quelques symboles forcés
            pw="$(openssl rand -base64 "$bytes" | tr -d '/+=' | cut -c1-"$length")"
            # s'assurer d'avoir au moins un symbole
            pw="${pw:0:$((length-1))}!"  # remplace la dernière par '!' — simple mais efficace
            printf "%s\n" "$pw"
        else
            openssl rand -base64 "$bytes" | tr -d '/+=' | cut -c1-"$length" && echo
        fi
    else
        # fallback vers /dev/urandom
        if [[ "$symbols" == "yes" ]]; then
            LC_ALL=C tr -dc 'A-Za-z0-9!@#$%&*()-_=+[]{}:;,./?' < /dev/urandom | head -c "$length"
        else
            LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
        fi
        echo
    fi
}
EOF
printf "%s\n" "Création du fichier core.sh [ terminé ]"
    [[ ! -x "$HOME/Service-Overtchat/Lib/core.sh" ]] && chmod +x "$HOME/Service-Overtchat/Lib/core.sh"
else
    printf "%s\n" "Fichier core.sh [ actif ]"; debug=1
fi

# Gestion Sql
if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Build" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Build > vers $HOME/Service-Overtchat ------"
    mkdir -p "$HOME/Service-Overtchat/Build"
fi

if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Build/Unix" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Unix > vers $HOME/Service-Overtchat/Build ------"
    mkdir -p "$HOME/Service-Overtchat/Build/Unix"
fi

if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Build/Windows" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Windows > vers $HOME/Service-Overtchat/Build ------"
    mkdir -p "$HOME/Service-Overtchat/Build/Windows"
fi

if [[ ! "$(find "$HOME/Service-Overtchat/Build/Unix" -type f -name "sql.sh" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "Création du fichier sql.sh [ en cours... ]"
    sleep 1
cat > "$HOME/Service-Overtchat/Build/Unix/sql.sh" <<'SQL'
#!/usr/bin/env bash

# --- Création/initialisation de la base SQL pour Service-Overtchat (avec pwgen) ---
setup_sql() {
    local conf_file="$HOME/Service-Overtchat/Users/data_sql.dat"
    mkdir -p "$(dirname "$conf_file")"

    printf "%s\n" "=== Installation / configuration MariaDB pour Service-Overtchat ==="

    read -rp "Hôte MariaDB (ou 'localhost') [localhost] : " sql_host
    sql_host=${sql_host:-localhost}

    read -rp "Chemin socket MySQL (laisser vide pour TCP) [/var/run/mysqld/mysqld.sock] : " sql_sock
    sql_sock=${sql_sock:-/var/run/mysqld/mysqld.sock}

    read -rp "Nom de la base à créer [overtchat] : " svc_db
    svc_db=${svc_db:-overtchat}

    read -rp "Nom de l'utilisateur service (utilisé par eggdrop/web) [overtchat_user] : " svc_user
    svc_user=${svc_user:-overtchat_user}

    # Mot de passe service (si vide -> on génère avec pwgen)
    read -rp "Mot de passe pour l'utilisateur service (laisser vide pour générer automatiquement) : " svc_pass
    if [[ -z "$svc_pass" ]]; then
        if command -v pwgen &>/dev/null; then
            svc_pass=$(pwgen -s 20 1)
        else
            # fallback sécurisé si pwgen absent
            svc_pass=$(openssl rand -base64 15)
        fi
        printf "Mot de passe généré : %s\n" "$svc_pass"
    fi

    # Compte admin pour créer DB / user
    read -rp "Admin DB user pour créer la base (ex: root) [root] : " admin_user
    admin_user=${admin_user:-root}
    read -rsp "Mot de passe admin MySQL pour $admin_user : " admin_pass
    printf "\n"

    read -rp "Nom de la table principale [overtchat_logs] : " svc_table
    svc_table=${svc_table:-overtchat_logs}

    # Construire la commande mysql selon socket ou host (on ne met pas le mot de passe en argv)
    local mysql_admin_cmd
    if [[ -n "$sql_sock" ]] && [[ "$sql_host" == "localhost" ]]; then
        mysql_admin_cmd=(mysql --socket="$sql_sock" -u"$admin_user" --batch --silent)
    else
        mysql_admin_cmd=(mysql -h "$sql_host" -u"$admin_user" --batch --silent)
    fi

    # Test de connexion admin (utilise MYSQL_PWD pour ne pas exposer en argv)
    if ! MYSQL_PWD="$admin_pass" printf "SELECT 1;\n" | "${mysql_admin_cmd[@]}" >/dev/null 2>&1; then
        echo "[ERROR] Impossible de se connecter à MariaDB avec les identifiants admin fournis."
        return 1
    fi

    echo "[INFO] Connexion admin OK — création de la base/utilisateur si besoin..."

    # SQL pour création DB, user, grant et table
    read -r -d '' SQL <<'EOF' || true
CREATE DATABASE IF NOT EXISTS `__DB__` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '__USER__'@'__HOST__' IDENTIFIED BY '__PASS__';
ALTER USER '__USER__'@'__HOST__' IDENTIFIED BY '__PASS__';
GRANT SELECT, INSERT, UPDATE, DELETE ON `__DB__`.* TO '__USER__'@'__HOST__';
FLUSH PRIVILEGES;
USE `__DB__`;
CREATE TABLE IF NOT EXISTS `__TABLE__` (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nick VARCHAR(64) NOT NULL,
    action VARCHAR(64) NOT NULL,
    payload TEXT,
    ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF

    # Substitutions sûres (on protège les quotes simples en remplaçant avant)
    local sql_host_for_grant="%"
    # Si l'utilisateur veut limiter à localhost, on met 'localhost'
    if [[ "$sql_host" == "localhost" || "$sql_host" == "127.0.0.1" ]]; then
        sql_host_for_grant="localhost"
    fi

    SQL="${SQL//__DB__/$svc_db}"
    SQL="${SQL//__USER__/$svc_user}"
    SQL="${SQL//__HOST__/$sql_host_for_grant}"
    # On échappe correctement le mot de passe pour l'insérer dans le script SQL
    # Ici on remplace ' par '\'' (méthode simple)
    local esc_pass="${svc_pass//\'/\'\\\'\'}"
    SQL="${SQL//__PASS__/$esc_pass}"
    SQL="${SQL//__TABLE__/$svc_table}"

    # Exécution SQL (encore via MYSQL_PWD pour sécurité)
    if ! MYSQL_PWD="$admin_pass" printf "%s\n" "$SQL" | "${mysql_admin_cmd[@]}" ; then
        echo "[ERROR] Échec lors de l'exécution des commandes SQL."
        return 1
    fi

    echo "[VALIDE] Base et table créées / mises à jour."

    # Écriture du fichier de conf
    cat > "$conf_file" <<CREATEUSERS
# Ip de connexion Mariadb
sql[hostname]="${sql_host}"
# Login Accés (utilisateur du service)
sql[login]="${svc_user}"
# Password Accés
sql[password]="${svc_pass}"
# Chemin du service socket pour mysql (laisser vide si TCP)
sql[sock]="${sql_sock}"
# Dossier Sql (nom de la base)
sql[database]="${svc_db}"
# Gestion table principale
sql[table]="${svc_table}"
CREATEUSERS

    chmod 600 "$conf_file"
    echo "[VALIDE] Fichier de config SQL écrit et protégé : $conf_file"

setup_sql "$@"
}
SQL
printf "%s\n" "Création du fichier sql.sh [ terminé ]"
    [[ ! -x "$HOME/Service-Overtchat/Build/Unix/sql.sh" ]] && chmod +x "$HOME/Service-Overtchat/Build/Unix/sql.sh"
else
    printf "%s\n" "Fichier sql.sh [ actif ]"; debug=1
fi

# Gestion Eggdrop
if [[ ! "$(find "$HOME" -type d -name "$HOME/Service-Overtchat/Eggdrop" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "------ Création du dossier < Build > vers $HOME/Service-Overtchat ------"
    mkdir -p "$HOME/Service-Overtchat/Eggdrop"
fi

if [[ ! "$(find "$HOME/Service-Overtchat/Eggdrop" -type f -name "egg.sh" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "Création du fichier egg.sh [ en cours... ]"
fi

if [[ -v debug && $debug -eq 1 ]]; then
    printf "%s\n" "Tout les fichiers de la Librairie sont existant"
else

cat << 'INFO'

Panel Information Important Service-Overtchat :

Cette section permet le contrôle des paquets nécessaires au bon fonctionnement du programme.
Si vous ne possèdez pas de droit ' root ', alors l'installation devra être arrêté, la commande ' sudo ' va être activé demandant vôtre mot de passe root !.
Si vous annulez l'installation, vous pourrez toujours télécharger le programme nécessitant pas une base Mysql et rester sur le mode TCL/SQLITE en mode limité.

            Voulez-vous continuer avec les accés ' root ' sur le programme Service-Overtchat ?
            => Appuyez sur Entrée pour continuer... ou appuyer sur N pour quitter. <=

INFO

    read -r -n1 response
    if [[ "$response" =~ [Nn] ]]; then
        echo && clear
        printf "%s\n" "Installation annulée par l'utilisateur. Au revoir !"
        install=0
    else
        install=1
    fi
fi
                                                #################################
                                                # === Installation Générale === #
                                                #################################

if [[ -v install && $install -eq 1 ]]; then
    if [[ -v debug && $debug -eq 0 ]]; then
        declare -A conf

    # On recherche le fichier de configuration
        conf[over]=$(find "$HOME/Service-Overtchat/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null)
        
        printf "%s\n" "Tentative de chargement du fichier source < ${conf[over]} >"
        sleep 1
        # si la variable existe
        [[ -v conf[over] ]] || { printf "%s\n" "Variable conf[over] manquante"; exit 1; }
        # on remet par defaut le mode numéric à null
        sed -i 's/numeric\[load\]=1/numeric[load]=null/' "${conf[over]}"
    
        # on charge le fichier trouvé
        source "${conf[over]}"; valid "Chargement réussi du fichier ${conf[over]}." || { printf "%s\n" "Échec du chargement de ${conf[over]}"; exit 1; }

        # on cherche si le fichier core.sh existe
        conf[over]=$(find "$HOME/Service-Overtchat/Lib" -type f -name "core.sh" -print -quit 2>/dev/null)
        # on scan les packages si source ok
        if [[ -v conf[over] ]]; then
            valid "Chargement réussi du fichier ${conf[over]}."; bash "${conf[over]}"
        fi

        # Création de la base de donnée Sql
        cat <<'SQL'

        Installation Sql => Appuyez sur Entrée pour continuer... ou appuyer sur N pour annulé. <=
SQL
        read -r -n1 response
        if [[ "$response" =~ [Nn] ]]; then
            printf "%s\n" "Ignorance de l'installation Sql !"
        else
            printf "%s\n" "Installation Sql [ en cours... ]"
            setup_sql=$(find "$HOME/Service-Overtchat/Build/Unix" -type f -name "sql.sh" -print -quit 2>/dev/null)
            [[ -v setup_sql ]]; bash "$setup_sql" || { printf "%s\n" "Erreur lancement install Sql"; exit 1; }
        fi

        # On déplace le programme original dans le bon dossier
        conf[over]=$(find "$HOME" -type f -name "$0" -print -quit 2>/dev/null)
        if [[ -v conf[over] ]]; then
            printf "%s\n" "Déplacement du fichier d'installation $0"
            [[ -v folders[dir_unix] ]]; mv "$HOME/$(basename $0)" "${folders[dir_unix]}/$(basename $0)"; printf "%s\n" "Déplacement $HOME/$(basename $0) validé vers ${folders[dir_unix]}/$(basename $0)" || { printf "%s\n" "Échec du déplacement de $(basename $0)"; exit 1; }
        fi

        # On valide le déplacement pour redemarrage
        conf[over]=$(find "$HOME/Service-Overtchat/Build/Unix" -type f -name "$(basename $0)" -print -quit 2>/dev/null)
        if [[ -v conf[over] ]]; then
            printf "%s\n" "Redémarrage du programme" 
            bash "${conf[over]}"
        else
            printf "%s\n" "Échec du redémarrage de $(basename $0)"
            exit 1
        fi
    fi
else
    cd "$HOME" && rm -rf "$HOME/Service-Overtchat"; exit 0
fi


                                                #############################
                                                # === Fonctions du menu === #
                                                #############################

# Option 1
show_logs() {
    if [[ -v files[logs] && -f "${files[logs]}" ]]; then
        clear
        warn "Contenu du fichier de logs : ${files[logs]}"
        if [[ -s "${files[logs]}" ]]; then
            cat "${files[logs]}"
        else
            echo "[VIDE] Aucun log à afficher."
        fi
    fi
}

# Option 2
funct_user() {
    # Date d’expiration dans 3 mois
    local expire_date user_file="${files[userlist]}"
    expire_date=$(date -d "+3 months" "+%Y-%m-%d")

    # Fichier de configuration manquant
    [[ -z "$user_file" ]] && error "Variable 'files[userlist]' absente." && return 1
    [[ ! -f "$user_file" ]] && error "Fichier $user_file introuvable." && return 1

    # --- Ajout d’un utilisateur ---
    if prompt_yn "Ajouter un pseudo ?"; then
        local adduser user_mail addgrade grade user_pass hash_pass

        read -rp "Pseudo à enregistrer : " adduser
        [[ -z "$adduser" ]] && return 1

        # Vérif doublon
        grep -q "user\[pseudo\]=$adduser" "$user_file" && error "Pseudo déjà présent." && return 1

        read_email "Email" user_mail || { error "Email non valide."; return 1; }

        # Sélection grade
        while :; do
            read -rp "Grade (1:Admin / 2:Geos / 3:Xop) : " addgrade
            case "$addgrade" in
                1) grade="Admin"; break;;
                2) grade="Geos";  break;;
                3) grade="Xop";   break;;
                *) warn "Valeur invalide."; ;;
            esac
        done

        # Génération et hash mot de passe
        user_pass="$(generate_password_safe 20 yes)" || return 1
        hash_pass=$(printf "%s" "$user_pass" | sha256sum | cut -d' ' -f1)

        cat <<EOF >> "$user_file"
user[pseudo]=$adduser
user[shell]=null
user[grade]=$grade
user[mail]=$user_mail
user[hostname]=$adduser@$(hostname)
user[date_register]=$(date)
user[expire_register]=$expire_date
user[register]=1
user[authentifie]=null
user[password]=$hash_pass

EOF
        valid "Utilisateur '$adduser' ajouté. Mot de passe : $user_pass"
        return 0
    fi

    # --- Suppression d’un utilisateur ---
    if prompt_yn "Supprimer un pseudo ?"; then
        local user_to_remove bak tmp
        read -rp "Pseudo à supprimer : " user_to_remove
        [[ -z "$user_to_remove" ]] && return 1

        grep -q "user\[pseudo\]=$user_to_remove" "$user_file" || { warn "Aucun utilisateur '$user_to_remove'"; return 0; }

        bak="${user_file}.$(date +%Y%m%d%H%M%S).bak"
        cp -- "$user_file" "$bak" || { error "Sauvegarde impossible."; return 1; }

        tmp=$(mktemp) || { error "Tmp impossible."; return 1; }

        awk -v user="$user_to_remove" '
            BEGIN { RS=""; ORS="\n\n" }
            $0 !~ ("user\\[pseudo\\][[:space:]]*=[[:space:]]*" user) { print $0 }
        ' "$user_file" > "$tmp"

        mv "$tmp" "$user_file"; valid "Suppression de '$user_to_remove' (sauvegarde : $bak)" ||
        { mv "$bak" "$user_file"; error "Échec suppression, restauration."; return 1; }

        return 0
    fi

    ${log[warn]} "Annulation."
    return 0
}

# Option 3
check_updates() {
    [[ ! -v web[data] ]] && error "Variable 'web[data]' manquante dans la configuration." && return 1
	
    check "Récupération des versions disponibles..."
	local info_file="${web[data]}"
	curl -s "${web[data]}" -o "$info_file"

	local web_version install_version
	web_version=$(grep -oP '"service-overtchat"\s*:\s*"\K[0-9.]+' "$info_file")
	install_version=$(grep -oP '"install.sh"\s*:\s*"\K[0-9.]+' "$info_file")

	echo -e "\n${CYAN}Versions disponibles sur le site :${NC}"
	echo "  - Service-Overtchat : $web_version"
	echo "  - install.sh        : $install_version"
	rm -f "$info_file"
}

# Option 4
maj_updates() {
	if [[ -v numeric[update] && "${numeric[update]}" -eq 1 ]]; then
		sed -i 's/numeric\[update\]=1/numeric[update]=0/' "${files[data]}"
		log "Mises à jour désactivées."
	elif [[ -v numeric[update] && "${numeric[update]}" -eq 0 ]]; then
		sed -i 's/numeric\[update\]=0/numeric[update]=1/' "${files[data]}"
		log "Mises à jour activées."
	else
        error "Valeur inconnue pour les mises à jour : ${numeric[update]}"
    fi
}

# Option 5
setup_overtchat() {
    printf "%s\n" "En construction"
}

# Option 6
uninstall() {
    conf[over]=$(find "$HOME" -type d -name "Service-Overtchat" -print -quit 2>/dev/null)
    read -rp "Valider la suppression de ${conf[over]} ( Y|N ) ? : " deleteall
    if [[ "$deleteall" =~ [Yy] ]]; then
        rm -rf "${conf[over]}"; printf "%s\n" "Désinstallation validé"; return 0
    else
        printf "%s\n\n" "Annulation de la désinstallation"; return 1
    fi
}

                                            ##########################
                                            # === Menu principal === #
                                            ##########################
panel() {
if [[ ! -v files[conf] && -f "$HOME/Service-Overtchat/Conf/overtchat.conf" ]]; then
    source "$HOME/Service-Overtchat/Conf/overtchat.conf"
fi
cat <<'PANEL'
                            Panel d'accueil du programme Service-Overtchat.

Veuillez faire vôtre choix :

        0) Quitter le programme ( Exit )
        1) Voir les logs du système ( Affiche le contenu du fichier de log Systême Service-Overtchat et les logs des autres Services)
        2) Info / Ajouter / Supprimer un User ( Agit à la base de données MariaDB )
        3) Vérifier les mises à jour ( Fait via GitHub si disponible )
        4) Activer/Désactiver mises à jour ( Active ou désactive la gestion automatique des mises à jour )
        5) Installer le programme (Service-Overtchat) ( Lance le script d'installation complet )
        6) Désinstaller le programme entièrement ( Action irréversible )

PANEL
}

while true; do
panel
read -rp "Entrer un chiffre : " number
    case "$number" in
        0) printf "%s\n" "Au revoir"; break ;;
		1) show_logs ;;
		2) funct_user ;;
		3) check_updates ;;
        4) maj_updates ;;
        5) setup_overtchat; break ;;
        6) uninstall ;;
		*) printf "%s\n" "Option invalide."; continue ;;
	esac
done