#!/bin/bash
set -euo pipefail
# nettoyage de l'ecran
clear

# Ici On créer le fichier configuration ce basant sur la gestion Mariadb permettant la gestion via phpmyadmin et Email
# On dépendra aussi du dépôt officiel pour les mises à jour GitHub

# On crontrôle les packages de base
REQUIRED_PACKAGES=("curl" "wget" "git" "bash" "sed" "awk" "grep" "chmod" "mkdir" "find" "read" "exit" "cat" "mariabd-client" "php" "php-mysql" "apache2" "libapache2-mod-php" "php-cli" "php-curl" "php-xml" "php-mbstring" "php-zip" "php-gd" "php-intl" "php-bcmath" "php-imagick" "mailutils" "dovecot-core" "dovecot-imapd" "dovecot-pop3d" "postfix" "php-mail" "php-pear" "php-mail-mime" "php-net-smtp" "php-net-socket" "phpmyadmin" "mariadb-server" "openssl" "ufw" "certbot" "python3-certbot-apache" "build-essential" "libssl-dev" "libffi-dev" "python3-dev" "python3-pip" "virtualenv" "tclsh" "expect" "tcl-dev" "python3-tk" "cron")

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! command -v "$pkg" &> /dev/null; then
        echo "Le package requis '$pkg' n'est pas installé. Veuillez l'installer avant de continuer."
        exit 1
    fi
done

# 1er lancement on regarde le dossier générale si existant
[[ ! -d "$HOME/Service-Overtchat" ]] && mkdir -p "$HOME/Service-Overtchat"
cd "$HOME/Service-Overtchat" || echo "Chargement impossible dans le dossier"; exit 1

cat > /tmp/irix_global.sh <<'GLOBAL'
init_variables() {
#!/usr/bin/env bash
declare -gA bot

# Informations Web
funtion bot[data_www]="http://service.overtchat.free.fr"

# Dossier source principale
funtion bot[overtchat]="Service-Overtchat"

# Fichier générale configuration Service Overtchat
funtion bot[source_conf_over]="${bot[overtchat]}/Conf/.overtchat.conf"

# Sous dossier source principale
funtion bot[data_overtchat]=${bot[overtchat]}/Build"

# Systême Exploitation
function bot[config_system]="Unix"
GLOBAL

# === Couleurs ===
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
NC="\e[0m"

# === Fonctions de base ===
log() { echo -e "${GREEN}[LOG]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
check() { echo -e "${CYAN}[CHECK]${NC} $1"; }

debug=0

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

# === Control Olders ===
config_file=$(find "$HOME" -type f -name "overtchat.conf" -print -quit 2>/dev/null)

if [[ -n "$config_file" && -e "$config_file" ]]; then
    CONFIG_FILE=$config_file
    source "$CONFIG_FILE"
else
    error "Fichier configuration introuvable !"
    exit 1
fi

for d in ".${over[name]}" "${paths[conf_dir]}" "${paths[log_dir]}" "${paths[bin_dir]}"; do
    if [[ ! -d "$d" ]]; then
        debug=-1
    fi
done

check_debug() {
    [[ $debug -eq 0 ]]
}

# === Fonctions du menu ===
show_logs() {
if check_debug; then
	echo -e "\n${CYAN}Contenu du fichier de logs :${NC} ${security[log]}"
	if [[ -s "${security[log]}" ]]; then
		cat "${security[log]}"
	else
		echo "[VIDE] Aucun log à afficher."
	fi
fi
}

update_user() {
if check_debug; then
	read -rp "Nom d’utilisateur à définir : " username
	if [[ -n "$username" ]]; then
		echo "username=\"$username\"" > "${security[dbuser]}"
		log "Utilisateur défini : $username"
	else
		warn "Aucun nom d’utilisateur fourni."
	fi
fi
}

reset_config() {
if check_debug; then
	if prompt_yn "Êtes-vous sûr de vouloir réinitialiser tous les fichiers ?"; then
		for f in "${security[dbuser]}" "${security[log]}" "${security[ban]}" "${security[user]}" "${security[error]}"; do
			rm -f "$f" && touch "$f" && chmod 600 "$f"
			log "Fichier réinitialisé : $f"
		done
	else
		log "Réinitialisation annulée."
	fi
fi
}

check_updates() {
if check_debug; then
	check "Récupération des versions disponibles..."
	local info_file="${paths[conf_dir]}/info.php"
	curl -s "${over[site]}/info.php" -o "$info_file"

	local web_version install_version
	web_version=$(grep -oP '"service-overtchat"\s*:\s*"\K[0-9.]+' "$info_file")
	install_version=$(grep -oP '"install.sh"\s*:\s*"\K[0-9.]+' "$info_file")

	echo -e "\n${CYAN}Versions disponibles sur le site :${NC}"
	echo "  - Service-Overtchat : $web_version"
	echo "  - install.sh        : $install_version"
	rm -f "$info_file"
fi
}

toggle_updates() {
if check_debug; then
	if [[ "${debug[maj]}" -eq 1 ]]; then
		sed -i 's/debug\[maj\]=1/debug[maj]=0/' "$CONFIG_FILE"
		log "Mises à jour désactivées."
	else
		sed -i 's/debug\[maj\]=0/debug[maj]=1/' "$CONFIG_FILE"
		log "Mises à jour activées."
	fi
fi
}

# === Menu principal ===

while true; do
	echo -e "\n${CYAN}╭─────── ${over[name]} v${debug[version]} ───────╮${NC}"
	echo -e "${CYAN}│${NC} 1) Voir les logs"
	echo -e "${CYAN}│${NC} 2) Ajouter / Modifier utilisateur"
	echo -e "${CYAN}│${NC} 3) Réinitialiser configuration"
	echo -e "${CYAN}│${NC} 4) Vérifier les mises à jour"
	echo -e "${CYAN}│${NC} 5) Activer/Désactiver mises à jour"
	echo -e "${CYAN}│${NC} 6) Installer le programme - install.sh"
	echo -e "${CYAN}│${NC} 7) Quitter"
	echo -e "${CYAN}╰────────────────────────────────────╯${NC}\n"
	
	if [[ $debug -lt 0 ]]; then
		echo -e "Statut : Installation Erronée. Merci de faire l'installation via < install.sh >"
	else
		echo -e "Statut : Installation Validée - Configuration Existante"
		if source "${over[source_off]}/${over[source_folders]}/${over[source_folders_config]}"; then
			echo -e "Statut : Configuration Chargée"
		else
			echo -e "Statut : Configuration Corrompu"
		fi
	fi

	read -rp "Choix : " choice
	case "$choice" in
		1) show_logs ;;
		2) update_user ;;
		3) reset_config ;;
		4) check_updates ;;
		5) toggle_updates ;;
		6) reset_setup ;;
		7) echo -e "${YELLOW}Au revoir.${NC}"; break ;;
		*) warn "Option invalide. Essayez encore." ;;
	esac
done
