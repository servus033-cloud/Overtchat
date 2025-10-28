#!/usr/bin/env bash
set -euo pipefail
clear

if [[ ! -f "/tmp/irix_global.sh" ]]; then
# Déclaration des variables globales
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

# Dossier Build réunissant les scripts des Eggdrops
funtion bot[name]="$HOME/${bot[source_data]}/IriX"

# Dossier principal configuration
funtion bot[config_overtchat]="${bot[overtchat]}/Conf/"


# Sous-Dossier Eggdrop
funtion bot[build_src]="${bot[name]}/Build"
funtion bot[build_conf]="${bot[name]}/Conf"
funtion bot[build_log]="${bot[name]}/Logs"

# Shell
funtion bot[panel]="${bot[build_src]}/panel.sh"
funtion bot[config]="${bot[build_conf]}/index.sh"
funtion bot[logo]="${bot[build_src]}/logo.sh"
funtion bot[check]="${bot[build_src]}/control.sh"
funtion bot[gestupdate]="${bot[build_src]}/update.sh"
funtion bot[gestlog]="${bot[build_src]}/logs.sh"
funtion bot[val-neg]="${bot[build_src]}/val_neg.sh"
funtion bot[makefile]="${bot[build_src]}/makefile.sh"
funtion bot[write]="${bot[build_src]}/model_write.sh"

# Fichiers Divers
funtion bot[log]="${bot[build_log]}/logs.dat"
}

# Code Couleur #
RED="\e[31m";
# shellcheck disable=SC2034
GREEN="\e[32m"; 
YELLOW="\e[33m";
# shellcheck disable=SC2034
CYAN="\e[36m"; 
NC="\e[0m";

# DEBUG
# shellcheck disable=SC2034
funtion debug=0

# Retour Messages #
function log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
function log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
function log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Affiche Horaire #
# shellcheck disable=SC2027
function times() { infotime=$(date +%H)"H"$(date +%M)"mn"$(date +%S)""; printf "%b\n" "$infotime"; }

# Enregistrement Logs #
function log() {
    if [ ! -d "${bot[build_log]}" ]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$(basename ${bot[log]})"
	else
        echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "${bot[log]}"
    fi
}
GLOBAL
fi

funtion allbug=0
# Contrôle de base du dossier principal
if [[ ! -d "${bot[source_data]}" ]]; then
    allbug=1
    log "${bot[source_data]} Erreur Install Primaire : Dossier source inconnu [ ${bot[source_data]} ]"
    log_error "Erreur Install Primaire : Dossier source inconnu [ ${bot[source_data]} ]. \
Veuillez (re)faire l'installation complète. \
Pour télécharger le programme : ${bot[data_www]} onglet '${bot[source_data]}'"
fi

if [[ ! -f "${bot[config_overtchat]}" ]]; then
    allbug=1
    log "${bot[config_overtchat]} Erreur Install Primaire : Fichier config inconnu [ ${bot[config_overtchat]} ]"
    log_error "Erreur Install Primaire : Fichier config inconnu [ ${bot[config_overtchat]} ]. \
Veuillez (re)faire l'installation complète."
fi

if [[ $allbug -eq 1 ]]; then
    log "Arrêt de l'installation en cours."
    log_error "Arrêt de l'installation en cours."; exit 1
fi

# Gestion du fichier global temporaire
# on controle sur la page web si une nouvelle version des variables existe 
# et on demande à l'utilisateur s'il veut la mettre à jour
# sinon on utilise l'ancienne version


if [[ -f "/tmp/irix_global.sh" ]]; then
    read -rp "Fichier init temporaire détecté. Voulez-vous le mettre à jour et le recréer ? (Y/N) " response
    case "${response,,}" in
        y|yes|o|oui)
            log "Suppression du fichier init temporaire."
            log_info "Suppression du fichier init temporaire."
            rm -f "/tmp/irix_global.sh"
        ;;
        n|no|non)
            log "Utilisation du fichier init temporaire existant."
            log_info "Utilisation du fichier init temporaire existant."
            ;;
        *)
            log "Réponse invalide. Utilisation du fichier ini temporaire existant par défaut."
            log_info "Réponse invalide. Utilisation du fichier global temporaire existant par défaut."
            ;;
    esac
fi

if [[ ! -f "/tmp/irix_global.sh" ]]; then
    log "Erreur : Fichier global manquant /tmp/irix_global.sh"
    log_error "Fichier global manquant /tmp/irix_global.sh"; exit 1
else
    source "/tmp/irix_global.sh"
    log "Fichier Init chargé avec succès."
    init_variables
fi

if [[ $? -ne 0 ]]; then
    log "Erreur : Échec du chargement du fichier Init."
    log_error "Échec du chargement du fichier Init."; exit 1
fi

# Création des dossiers si inexistants
scan_folders=( 
    "${bot[build_src]}"
    "${bot[build_conf]}"
    "${bot[build_log]}"
)

log "Contrôle des sous-dossiers"
for folder in "${scan_folders[@]}"; do
	if [[ -n "$folder" && ! -d "$folder" ]]; then
		if mkdir -p "$folder"; then
			log "Création du dossier : $folder" && log_info "Dossier créé : $folder"; true
		else
			log "Impossible de créer : $folder" && log_error "Dossier érroné: $folder"; false
		fi
	fi
done

# création du fichier data
create_data_file() {
	if [[ ! -f "$1" ]]; then
        log "Création du fichier [ $1 ]"
		log_warn "Création du fichier [ $1 ]"
	fi
    log "Fichier [ $1 ] Validé."
	log_info "Fichier [ $1 ] Validé."
}

# Logo Animé IriX
! create_data_file "${bot[logo]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat > "${bot[logo]}" <<EOF
#!/usr/bin/env bash

# --- Fonction d'affichage lettre par lettre ---
type_effect() {
    local text="$1"
    local delay="${2:-0.003}" # vitesse (en secondes)
    for ((i=0; i<${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep "$delay"
    done
    printf "\n"
}

# --- Barre de progression ---
loading_bar() {
    local message="$1"
    local total=20
    local delay=0.05

    for ((i=0; i<=total; i++)); do
        local percent=$((i * 100 / total))
        local done_bar=$(printf "%-${i}s" "" | tr ' ' '#')
        local empty_bar=$(printf "%-$((total - i))s" "" | tr ' ' '-')
        printf "\r\e[1;36m%s [%s%s] %3d%%\e[0m" "$message" "$done_bar" "$empty_bar" "$percent"
        sleep "$delay"
    done
}

# --- Logo animé ---
panel_bot() {
    local color="\e[1;34m"
    local reset="\e[0m"

    local logo="
 ___      _ __   __
|_ _|_ __(_)\ \|/ /
 | || '__| | \ . /
 | || |  | | / . \\
|___|_|  |_|/_ |\\_\\

         Bienvenue sur IriX, la nouvelle génération créée par SerVuS.
"

    local term_width
    term_width=$(tput cols 2>/dev/null)
    [[ -z "$term_width" || "$term_width" -le 0 ]] && term_width=80

    printf "%b" "$color"
    printf '%*s\n' "$term_width" '' | tr ' ' '-'

    while IFS= read -r line; do
        local padding=$(( (term_width - ${#line}) / 2 ))
        (( padding < 0 )) && padding=0
        printf "%*s" "$padding" ""
        # Effet machine à écrire
        for (( i=0; i<${#line}; i++ )); do
            printf "%s" "${line:i:1}"
            sleep 0.02
        done
        echo
    done <<< "$logo"

    printf '%*s\n' "$term_width" '' | tr ' ' '-'
    printf "%b" "$reset"
}
EOF
fi

! create_data_file "${bot[check]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat > "${bot[check]}" <<'LOOP'
#!/usr/bin/env bash

# Vérification de la connexion Internet
check_internet() {
	if ! ping -c1 -W2 1.1.1.1 &>/dev/null; then
		return 1
	else
		return 0
	fi
}

# Controle des fichiers
control_file_conf() {
	if [[ -f "${1:-}" ]]; then
		return 0
	else
		return 1
	fi
}

# On install si dossier non existant
control_folder() {
	if [[ -d "${1:-}" ]]; then 
		return 0
	else
		return 1
	fi
}

# Recherche un fichier dans un répertoire Intelligent
find_dir() {
	find "$1" -type f -name "$2" -print -quit 2>/dev/null
}
LOOP
fi

! create_data_file "${bot[gestupdate]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat > "${bot[gestupdate]}" <<'UPD'
# System Update
load_maj() {
	if ! control_file_conf "${bot[config]}"; then
		return 1
	fi
	
	if [[ -e "${bot[maj]}" && "${bot[maj]}" -eq 0 ]]; then
		return 0
	elif [[ -e "${bot[maj]}" && "${bot[maj]}" -eq 1 ]]; then
		return 1
	fi
}
UPD
fi

! create_data_file "${bot[gestlog]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat > "${bot[gestlog]}" <<'EOF'
#!/usr/bin/env bash

# Création du fichier log
rotate_logs() {
    # Vérifier que le tableau associatif existe
    if ! declare -p bot &>/dev/null || [[ -z "${bot[conf]:-}" ]] || [[ -z "${bot[log_file]:-}" ]]; then
        return 0  # On ignore la rotation
    fi

    # Vérifier que le fichier log est bien géré par la conf
    if control_file_conf "${bot[log_file]}"; then
        if [[ $(stat -c%s "${bot[log_file]}") -ge ${bot[max_size]:-1048576} ]]; then
            # Supprimer le plus vieux log si on atteint la limite
            if control_file_conf "${bot[log_file]}.${bot[max_rotations]:-5}"; then
                rm -f "${bot[log_file]}.${bot[max_rotations]:-5}"
            fi
            # Décaler les logs existants
            for ((i=${bot[max_rotations]:-5}-1; i>=1; i--)); do
                if control_file_conf "${bot[log_file]}.$i"; then
                    mv "${bot[log_file]}.$i" "${bot[log_file]}.$((i + 1))"
                fi
            done
        fi
        # Rotation du log courant
        mv "${bot[log_file]}" "${bot[log_file]}.1"
        touch "${bot[log_file]}"
    else
        touch "${bot[log_file]}"
    fi
}


# Exécution de la rotation avant chaque écriture
log_msg() {
    # Vérifie que le tableau bot et la clé log_file existent
    if ! declare -p bot &>/dev/null || [[ -z "${bot[log_file]:-}" ]]; then
        # Si pas de log_file, on log juste sur la sortie standard
        local type="${1^^}"
        local msg="$2"
        printf "[%s] %s\n" "$type" "$msg"
        return 0
    fi

    rotate_logs
    local type="${1^^}"
    local msg="$2"
    printf "[%s] %s\n" "$type" "$msg" | tee -a "${bot[log_file]}"
}
EOF
fi

! create_data_file "${bot[val-neg]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat > "${bot[val-neg]}" <<'DEV'
#!/usr/bin/env bash

# Téléchargement
download_x() {
	if [[ -e "${bot[wget]}" ]]; then
		case "${bot[wget]}" in
			1) 
				if wget --quiet -P ${1:-} ${2:-}; then
					log_msg "VALIDE" "Téléchargement silent ok"
				else
					log_msg "ERREUR" "Téléchargement : ${1:-} ${2:-}"; return 1
				fi
			;;
			0) 
				if wget -P ${1:-} ${2:-}; then
					log_msg "VALIDE" "Téléchargement ok"
				else
					log_msg "ERREUR" "Téléchargement : ${1:-} ${2:-}"; return 1
				fi
			;;
			*) log_msg "ERREUR" "Systême download"; return 1 ;;
		esac
	fi
}

# Confirmation
confirm_yn() {
	local prompt="${1:-Confirmer ? (Y/N)}"
	local rep
	while true; do
		read -rp "$prompt " rep
		
		# Mise en minuscule
		local rep_cleaned="${rep,,}"         # tout en minuscules
		rep="${rep_cleaned// /}"     # supprime les espaces
		
		case "$rep" in
			y|o*) return 0 ;;
			n*) return 1 ;;
			*) printf "%b\n" "Veuillez répondre par Y ou N." ;;
		esac
	done
}

# Arret prog
annul_prog() {
	printf "%b\n" "${1-:}"
	sleep 2; clear
	# suppression du dossier principal
	[[ -d "${bot[name]}" ]] && rm -rf "${bot[name]}"; exit 1
}

# Arret prog
arret_prog() { 
	printf "%b\n" "${1-:}"; exit 1 
}
DEV
fi

! create_data_file "${bot[makefile]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat >> "${bot[makefile]}" <<'MAKE'
# Installation
INSTALL() {
	if ! check_internet; then
		log_error "Connexion internet requise pour l'installation."; exit 1
	fi
	if ! control_folder "$HOME/$(basename ${bot[name]})"; then
		if ! confirm_yn "$txt"; then
			annul_prog "Installation annulé. Merci d'avoir choisi nôtre programme"
		else
			install_continue_packages
			main_menu
		fi
	else
		main_menu
	fi
}

# Installation
MAKEINSTALL() {
	if scan_folders; then
		if create_bot_config; then
			if eggdrop_create; then
				if create_bot_conf; then
					log_info "Installation réussie."; sleep 2
					main_menu
				else
					log_error "Échec de la création du fichier $(basename ${bot[name]}).conf."
					exit 1
				fi
			fi
		else
			log_error "Échec de la création de $(basename ${bot[name]})."
			exit 1
		fi
	else
		log_error "Échec de la vérification des dossiers."
		exit 1
	fi
}
MAKE
fi

! create_data_file "${bot[write]}" && debug=1

if [[ $debug -eq 1 ]]; then
debug=0; cat > "${bot[write]}" <<'ENDSCRIPT'
#!/usr/bin/env bash
# Affichage style "machine à écrire" pour chaque vérif
loading_bar_step() {
    local percent=$1
    local name="$2"
    local done=$(( (percent * 20) / 100 ))
    local left=$(( 20 - done ))
    printf "\r[%s%s] %3d%% - Vérification : %s" \
        "$(printf '#%.0s' $(seq 1 $done))" \
        "$(printf ' %.0s' $(seq 1 $left))" \
        "$percent" "$name"
}

# Animation de la barre (0% -> 100%)
animate_loading_bar() {
    local name="$1"
    for p in $(seq 0 5 100); do
        loading_bar_step "$p" "$name"
        sleep 0.02
    done
    echo ""
}
ENDSCRIPT
fi

build_select=(
    "${bot[check]}"
    "${bot[gestlog]}"
    "${bot[val-neg]}"
    "${bot[gestupdate]}"
    "${bot[makefile]}"
    "${bot[logo]}"
    "${bot[config]}"
    "${bot[write]}"
)

for xtrans in "${build_select[@]}"; do
    if [[ ! -f "$xtrans" ]]; then
        log "Fichier manquant : $xtrans"
        log_error "Fichier manquant : $xtrans"
        exit 1
    fi
done

# Si tout va bien, on les source :
for xtrans in "${build_select[@]}"; do
    # shellcheck disable=SC1090
    source "$xtrans"
done

# Si tout est bon , alors on continue
# nettoyage de l'écran
clear

# Chargement logo
sleep 2; panel_bot
# Barre de chargement
sleep 0.5
echo

exit 1

# Compilation
log_msg "COMPIL" "Démarrage de la compilation..."
compile_prog() {
	local mode=""
	local umode=""
	local prompt="${1:-}"
	if ! control_file_conf "$prompt.tar.gz"; then
		log_msg "ERREUR" "Téléchargement $prompt"
		return 1
	fi
	# compile ok
	if tar -zxf "$prompt.tar.gz"; then
		cd "$prompt"
		[[ ${bot[wget]} -eq 1 ]] && mode="-s" && umode="--silent"
		./configure $umode --prefix=${bot[name]}
		make config $mode
		make $mode
		make install $mode
		if confirm_yn "Souhaitez-vous installer le certificat SSL sur l'eggdrop ?"; then
			make sslcert $mode
		fi
		cd "${bot[name]}"
	else
		log_msg "ERREUR" "Compilation $prompt"; return 1
	fi
}

# On active ou pas l'install
txt="Bienvenue sur $(basename "${bot[name]}") en gestion SQL et installé en version Stable par défaut.
Un contrôle des packages sera effectué pour contrôler la compatibilité du programme.
Si une incompatibilité est détecté, autorisé les intallations automatiquement en root.
-
Une activation du mode < root > via 'sudo' pourra être faite sur $(basename ${bot[name]}).
-
Souhaitez-vous continuer ? (Y/N) "

# Vérification des paquets requis
install_continue_packages() {
	 local marker="$HOME/.irix_packages_checked"

    # Si le fichier existe -> on saute le scan
    if [[ -f "$marker" ]]; then
        echo "[INFO] Les paquets ont déjà été vérifiés, scan ignoré."
        return 0
    fi

    local pkg_list1=( mailutils libssl-dev libreadline-dev libncurses5-dev build-essential )
    local cmd_list=( wget shc gcc make sed awk grep cut tr chmod touch rm mv cp hostname date tcl-dev tcl8.6 mutt automake autoconf phpmyadmin mariadb-server mariadb-client mariadb-common mariadb-server-core mariadb-client-core )

    echo -e "\n[$(basename ${bot[name]}) SCAN 1/2] \nVérification des paquets requis...\n"
    for pkg in "${pkg_list1[@]}"; do
        animate_loading_bar "$pkg"
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            log_info " $pkg ${YELLOW}déjà installé${NC}"
        else
            log_info " $pkg ${RED}manquant${NC}"
            if confirm_yn "Installer '$pkg' avec sudo ? (Y/N)"; then
                if sudo apt update && sudo apt install -y "$pkg"; then
                    log_info " '$pkg' ${GREEN}Installé${NC}"
                else
                    annul_prog " Erreur lors de l'installation de '$pkg'. Arrêt."
                fi
            else
                annul_prog " Installation refusée. Programme incompatible."
            fi
        fi
    done

    # --- Vérification serveur mail ---
    animate_loading_bar "Serveur mail"
    local have_postfix=false
    local have_exim4=false

    if dpkg -s postfix >/dev/null 2>&1; then
        have_postfix=true
    fi
    if dpkg -s exim4 >/dev/null 2>&1; then
        have_exim4=true
    fi

    if $have_postfix && $have_exim4; then
        annul_prog "Conflit : Postfix et Exim4 sont installés. Veuillez en désinstaller un."
    elif $have_postfix; then
        log_info " Serveur mail : Postfix ${YELLOW}déjà installé${NC}"
    elif $have_exim4; then
        log_info " Serveur mail : Exim4 ${YELLOW}déjà installé${NC}"
    else
        echo -e "Aucun serveur mail détecté\nChoisir un serveur mail à installer :\n1) Postfix (recommandé)\n2) Exim4"
        read -rp " Votre choix [1-2] : " choice
        case "$choice" in
            1)
                echo "postfix postfix/mailname string localhost" | sudo debconf-set-selections
                echo "postfix postfix/main_mailer_type string 'Internet Site'" | sudo debconf-set-selections
                if sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y postfix; then
                    log_info " Postfix ${GREEN}Installé${NC}"
                else
                    annul_prog "Erreur lors de l'installation de Postfix"
                fi
            ;;
            2)
                echo "exim4-config exim4/dc_eximconfig_configtype select 'internet site; mail is sent and received directly using SMTP'" | sudo debconf-set-selections
                echo "exim4-config exim4/mailname string localhost" | sudo debconf-set-selections
                if sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y exim4; then
                    log_info " Exim4 ${GREEN}Installé${NC}"
                else
                    annul_prog "Erreur lors de l'installation d'Exim4"
                fi
            ;;
            *)
                echo "Choix invalide. Arrêt."
        	;;
        esac
    fi

    echo -e "\n[$(basename ${bot[name]}) SCAN 2/2] \nVérification des commandes requises...\n"
    for cmd in "${cmd_list[@]}"; do
        animate_loading_bar "$cmd"

        # Vérif double : apt/dpkg puis command -v
        if dpkg -s "$cmd" >/dev/null 2>&1 || command -v "$cmd" >/dev/null 2>&1; then
            log_info " $cmd ${YELLOW}déjà installé${NC}"
        else
            log_info " $cmd ${RED}manquant${NC}"
            if confirm_yn "Installer '$cmd' avec sudo ? (Y/N)"; then
                if sudo apt update && sudo apt install -y "$cmd"; then
                    log_info " '$cmd' ${GREEN}Installé${NC}"
                else
                    annul_prog " Erreur lors de l'installation de '$cmd'. Arrêt."
                fi
            else
                annul_prog " Installation refusée. Programme incompatible."
            fi
        fi
    done

    # On purge sudo
	if confirm_yn "Souhaitez-vous purger les paquets inutiles ( Accès root ! ) ? (Y/N)"; then
   		sudo apt autoremove -y
	else
		echo -e "\nPurge des paquets inutiles annulée.\n"
	fi
	sleep 2; clear
	# Création du marqueur pour éviter les scans futurs
	touch "$marker"
	log_info "Vérification des paquets terminée. Marqueur créé : $marker"
	return 0
}
												# Si tout ok, alors on install


# Création du fichier config
create_bot_config() {
    ! declare bot && declare -A bot

    if ! control_file_conf "${bot[config]}"; then
        printf "[%s Build] Fichier configuration < %s > ...\n" \
            "$(basename "${bot[name]}")" "${bot[config]}"

        # Questions utilisateur -> valeurs 0/1
        bot[wget]=$(confirm_yn "Activer le mode < silent > pour wget ? (Y/N)" && echo 1 || echo 0)
        log_msg "WGET" "Mode silent $( [[ ${bot[wget]} -eq 1 ]] && echo 'activé' || echo 'désactivé')"

        bot[beta]=$(confirm_yn "Voulez-vous obtenir la version < Beta > ? (Y/N)" && echo 1 || echo 0)
        bot[meta]=0
        if [[ ${bot[beta]} -eq 0 ]]; then
            bot[meta]=$(confirm_yn "Voulez-vous obtenir la version < Stable > ? (Y/N)" && echo 1 || echo 0)
        fi

        bot[tcl]=$(confirm_yn "Utiliser le programme basé sur Tcl ? (Y/N)" && echo 1 || echo 0)
        bot[sql]=0; bot[other]=0
        if [[ ${bot[tcl]} -eq 0 ]]; then
            bot[sql]=$(confirm_yn "Utiliser Sqlite/MariaDB ? (Y/N)" && echo 1 || echo 0)
            if [[ ${bot[sql]} -eq 0 ]]; then
                bot[other]=$(confirm_yn "Utiliser un autre moteur de BDD ? (Y/N)" && echo 1 || echo 0)
            fi
        fi

        bot[maj]=$(confirm_yn "Activer les mises à jour automatiques ? (Y/N)" && echo 1 || echo 0)

        # Écriture du fichier de config (interprétation des variables -> pas de quotes sur EOF)
cat > "${bot[config]}" <<EOF
# Fichier de configuration #
declare -A bot

# Nom Principal
bot[name]="$(basename "${bot[name]}")"

# Dossiers
bot[src]="${bot[name]}/src"
bot[conf]="${bot[name]}/conf"
bot[log]="${bot[name]}/logs"

# Fichiers
bot[config]="${bot[conf]}/.index"
bot[update]="${bot[conf]}/.update"
bot[panel]="${bot[src]}/.panel"
bot[prog]="${bot[src]}/.installirix"

# Update/Upgrade
bot[versprog]="${bot[versprog]}"
bot[maj]="${bot[maj]}"

# Logs
bot[log_file]="${bot[log]}/.logerror"
bot[max_size]=1048576
bot[max_rotations]=5

# Options
bot[beta]="${bot[beta]}"
bot[meta]="${bot[meta]}"
bot[tcl]="${bot[tcl]}"
bot[sql]="${bot[sql]}"
bot[other]="${bot[other]}"
bot[wget]="${bot[wget]}"

# Web
bot[web]="http://service.overtchat.free.fr"

# Gestion Eggdrop
bot[sourceegg]="eggdrop-1.10.0"
bot[siteegg]="https://ftp.eggheads.org/pub/eggdrop/source/1.10/${bot[sourceegg]}.tar.gz"

# Infos générales
bot[description]="Un bot IRC polyvalent"
bot[author]="Service-Overtchat"
EOF

        log_msg "CONFIG" "Fichier config généré : ${bot[config]}"
    fi

    # Chargement
    source "${bot[config]}"
}

# Création Eggdrop
eggdrop_create() {

	download_silent "$HOME" "${bot[siteegg]}"
	compile_prog "${bot[sourceegg]}"

	# Vérification de la création du dossier
	if [[ ! -d "${bot[name]}" ]]; then
		arret_prog "Dossier inexistant : $(basename "${bot[name]})""
	fi

	# Suppression des anciens fichiers TCL
	prog_del=$(find_dir "${bot[name]}/scripts" "*.tcl")
	if [[ -n "$prog_del" ]]; then
		rm -f "$prog_del"
		log_msg "DELETE" "Suppression de : $prog_del"
	fi

	# Téléchargement selon version
	local script_dir="${bot[name]}/scripts"
	local base_url="http://${bot[web]}/$(basename "${bot[name]}")"

	# Version Stable
	if [[ ${bot[meta]} -eq 1 ]]; then
		# programme
		[[ ${bot[tcl]} -eq 1 ]] && download_x "$script_dir" "$base_url/Stable/$(basename "${bot[name]}")-std.tcl"
		[[ ${bot[sql]} -eq 1 ]] && download_x "$script_dir" "$base_url/Stable/$(basename "${bot[name]}")-sql.tcl"
	# Version Beta
	elif [[ ${bot[beta]} -eq 1 ]]; then
		[[ ${bot[tcl]} -eq 1 ]] && download_x "$script_dir" "$base_url/Beta/$(basename "${bot[name]}")-std.tcl"
		[[ ${bot[sql]} -eq 1 ]] && download_x "$script_dir" "$base_url/Beta/$(basename "${bot[name]}")-sql.tcl"
	else
		arret_prog "Enregistrement du programme corrompu"
	fi
	return 0
}

# Lecture sécurisée
read_secure() {
	local prompt="$1"
	local input
	read -rp "$prompt" input
	echo "$input"
}

# Lecture guidée selon le type de donnée
compil_egg() {
	local key="$1"
	local prompt=""
	local rep=""

	case "$key" in
		host)   prompt="Host de Connexion du Serveur : " ;;
		port)   prompt="Port de Connexion du Serveur : " ;;
		user)   prompt="Votre Pseudo : " ;;
		email)  prompt="Votre email : " ;;
		iploc)  prompt="IP locale : " ;;
		chans)  prompt="Salon à ouvrir : " ;;
		*)      echo "Clé inconnue : $key" ; return 1 ;;
	esac

	read -rp "$prompt" rep
	echo "$rep"
}

# Création du fichier eggdrop.conf
create_bot_conf() {
	# Vérification du mode SQL
	if [[ ${bot[sql]} -eq 1 ]]; then
		if confirm_yn "Mode SQL activé. Avez-vous un accès SQL sur phpmyadmin/mariadb ?"; then
			bot[host]=$(compil_egg "host")
			bot[db]=$(read_secure "Nom de la Database Principal : ")
			bot[password]=$(read_secure "Mot de passe de la Database : ")
			bot[xdb]=$(read_secure "Nom de la base à créer : ")

			# Enregistrement des données SQL
			cat <<EOF >> "${bot[config]}"
# Access SQL
bot[host]=${bot[host]}
bot[db]=${bot[db]}
bot[password]=${bot[password]}
bot[xdb]=${bot[xdb]}
EOF
		else
			log_msg "ARRET" "Annulation SQL : Accès refusé"
			return 1
		fi
	fi

	# Collecte des infos générales
	for key in host port user email iploc chans; do
		bot[$key]=$(compil_egg "$key")
	done

	# Affichage pour vérification
	echo "Configuration du bot :"
	for key in "${!bot[@]}"; do
		echo "$key => ${bot[$key]}"
	done

	# Création du fichier de configuration
	local conf_path="${bot[name]}/$(basename "${bot[name]}").conf"

	cat <<EOF > "$conf_path"
# Fichier de configuration pour $(basename "${bot[name]}")
# Créé par Service-Overtchat V1.5

addlang "french"
logfile mco * "logs/$(basename "${bot[name]}").log"

loadmodule pbkdf2
loadmodule blowfish
loadmodule dns
loadmodule server
loadmodule ctcp
loadmodule irc
loadmodule share
loadmodule filesys
loadmodule compress
loadmodule notes
loadmodule console
loadmodule seen
loadmodule assoc
loadmodule uptime
loadmodule channels

set files-path "$HOME/filesys"
set incoming-path "$HOME/filesys/incoming"
set net-type "IRCnet"
set nick "$(basename "${bot[name]}")"
set altnick "$(basename "${bot[name]}")"
set username "${bot[user]}"
set admin "${bot[user]} ${bot[email]}"
set owner "${bot[user]}"
set network "${bot[host]}"
set realname "Service $(basename "${bot[name]}")"
set default-port ${bot[port]}
server add ${bot[host]} ${bot[port]}
listen ${bot[iploc]} 7700 all

unbind dcc n tcl *dcc:tcl
unbind dcc n set *dcc:set
unbind dcc n simul *dcc:simul
unbind msg - ident *msg:ident
unbind msg - addhost *msg:addhost
set timezone "CET"
set offset "5"
#set env(TZ) "$timezone$offset"
set prefer-ipv6 0
set max-logs 20
set max-logsize 0
set quick-logs 0
set raw-log 0
set log-time 1
set timestamp-format {[%H:%M:%S]}
set keep-all-logs 0
set logfile-suffix ".%d%b%Y"
set switch-logfiles-at 300
set quiet-save 0
set console "mkcoblxs"
set userfile "init.user"
set pidfile "init.pid"
set notefile "init.notes"
set help-path "help/"
set text-path "text/"
set motd "text/motd"
set telnet-banner "text/banner"
set userfile-perm 0600
set botnet-nick "$(basename "${bot[name]}")_botnet"
set remote-boots 2
set share-unlinks 1
set protect-telnet 0
set dcc-sanitycheck 0
set ident-timeout 5
set require-p 1
set open-telnets 0
set stealth-telnets 0
set stealth-prompt "Nickname :"
set use-telnet-banner 0
set connect-timeout 15
set dcc-flood-thr 3
set telnet-flood 5:60
set paranoid-telnet-flood 1
set resolve-timeout 5
#set ssl-privatekey "check.key"
#set ssl-certificate "check.crt"
#set ssl-verify-depth 9
set ssl-capath "/etc/ssl/"
#set ssl-cafile ""
#set ssl-protocols "TLSv1 TLSv1.1 TLSv1.2 TLSv1.3" 
#set ssl-ciphers ""
#set ssl-dhparam "dhparam.pem"
#set ssl-cert-auth 0
#set ssl-verify-bots 0
#set ssl-verify-clients 0
#set firewall "!sun-barr.ebay:3666"
#set nat-ip "127.0.0.1"
#set reserved-portrange 2010:2020
#set ssl-verify-server 0
set ignore-time 15
set hourly-updates 00
set notify-newusers "$owner"
set default-flags "hp"
set whois-fields "url birthday"
set must-be-owner 1
set max-socks 100
set allow-dk-cmds 1
set dupwait-timeout 5
set cidr-support 0
set show-uname 1
set mod-path "modules/"
#set pbkdf2-method "SHA256"
#set pbkdf2-rounds 16000
#set remove-pass 0
set blowfish-use-mode cbc
#set dns-servers "8.8.8.8 1.1.1.1 192.168.0.254"
set dns-cache 86400
set dns-negcache 600
set dns-maxsends 4
set dns-retrydelay 3
set chanfile "init.chan"
set force-expire 0
set share-greet 0
set use-info 1
set allow-ps 0
set default-flood-chan 15:60
set default-flood-deop 3:10
set default-flood-kick 3:10
set default-flood-join 5:60
set default-flood-ctcp 3:60
set default-flood-nick 5:60
set default-aop-delay 5:30
set default-idle-kick 0
set default-chanmode "nt"
set default-stopnethack-mode 0
set default-revenge-mode 0
set default-ban-type 3
set default-ban-time 120
set default-exempt-time 60
set default-invite-time 60
#set sasl 0
set msg-rate 2
set keep-nick 1
set quiet-reject 1
set lowercase-ctcp 0
set answer-ctcp 3
set flood-msg 5:60
set flood-ctcp 3:60
set server-cycle-wait 60
set server-timeout 60
set check-stoned 1
set serverror-quit 1
set max-queue-msg 300
set trigger-on-ignore 0
set exclusive-binds 0
set double-mode 1
set double-server 1
set double-help 1
set optimize-kicks 1
set stack-limit 4
#set check-mode-r 0
#set nick-len 9
set ctcp-mode 1
set bounce-bans 0
set bounce-exempts 0
set bounce-invites 0
set bounce-modes 0
set learn-users 0
set wait-split 600
set wait-info 180
set mode-buf-length 200
set opchars "@"
set no-chanrec-info 0
set prevent-mixing 1
set upload-to-pwd 0
set filedb-path ""
set max-file-users 20
set max-filesize 1024
set max-notes 50
set note-life 60
set allow-fwd 0
set notify-users 0
set notify-onjoin 1
set console-autosave 1
set force-channel 0
set info-party 0

set default-chanset {
        -autoop         -autovoice
        -bitch          +cycle
        +dontkickops    +dynamicbans
        +dynamicexempts +dynamicinvites
        -enforcebans    +greet
        -inactive       -nodesynch
        -protectfriends +protectops
        -revenge        -revengebot
        -secret         -seen
        +shared         -statuslog
        +userbans       +userexempts
        +userinvites    -protecthalfops
        -autohalfop     -static
}

#die "Please make sure you edit your config file completely."
#bind evnt - init-server evnt:init_server

if {[file exists aclocal.m4]} { die {You are attempting to run Eggdrop from the source directory. Please finish installing Eggdrop by running "make install" and run it from the install location.} }
#set isupport-default "CASEMAPPING=rfc1459 CHANNELLEN=80 NICKLEN=9 CHANTYPES=#& PREFIX=(ov)@+ CHANMODES=b,k,l,imnpst MODES=3 MAXCHANNELS=10 TOPICLEN=250 KICKLEN=250 STATUSMSG=@+"" > "$conf_path"
EOF

	# Ajout des sources TCL selon le mode
	echo -e "\nchannel add ${bot[chans]}" >> "$conf_path"
	if [[ ${bot[tcl]} -eq 1 ]]; then
		echo -e "#source scripts/$(basename ${bot[name]})-std.tcl" >> "$conf_path"
	elif [[ ${bot[sql]} -eq 1 ]]; then
		echo -e "#source scripts/$(basename ${bot[name]})-sql.tcl" >> "$conf_path"
	fi
	log_msg "CREATE" "Fichier de configuration créé : $conf_path"
	return 0
}

show_help() {
	cat <<EOF

Usage : $0 [option]

Options disponibles :
  help			→ Affiche cette aide
  start			→ Lance l’installation du programme
  upgrade		→ Met à jour le programme
  uninstall		→ Désinstalle complètement le programme
  info			→ Affiche les infos du programme

EOF
	sleep 2; main_menu
}

info_gene_panel() {
	if [[ -d "${bot[name]}" ]]; then
		bot[installed]="Oui"
	else
		bot[installed]="Non"
	fi

	if [[ -f "${bot[config]}" ]]; then
		. "${bot[config]}"
	else
		bot[description]="Null"
		bot[version]="0.0.0"
		bot[author]="Service-Overtchat"
	fi

	# Champs à afficher (clé=valeur)
	local -A fields=(
		["Nom du bot"]="$(basename "${bot[name]}")"
		["Installé"]="${bot[installed]}"
		["Description"]="${bot[description]}"
		["Version"]="${bot[version]}"
		["Auteur"]="${bot[author]}"
	)

	# Calculer la largeur max
	local max_key=0 max_val=0
	for k in "${!fields[@]}"; do
		(( ${#k} > max_key )) && max_key=${#k}
		(( ${#fields[$k]} > max_val )) && max_val=${#fields[$k]}
	done

	# Largeur totale du contenu (clé + " : " + valeur)
	local content_width=$(( max_key + 2 + max_val ))
	local total_width=$(( content_width + 2 )) # +2 pour les espaces autour

	# Ligne du haut
	printf "${CYAN}╭─ Information Générale - %s " "$(basename "${bot[name]}")"
	# compléter avec des tirets jusqu'à la largeur
	local title_len=$(( ${#bot[name]} + 26 ))
	for ((i=title_len; i<total_width; i++)); do printf "─"; done
	printf "╮${NC}\n"

	# Afficher chaque ligne
	for k in "Nom du bot" "Installé" "Description" "Version" "Auteur"; do
		printf "${CYAN}│${NC} %-*s : %-*s ${CYAN}│${NC}\n" \
			"$max_key" "$k" "$max_val" "${fields[$k]}"
	done

	# Ligne du bas
	printf "${CYAN}╰"; for ((i=0; i<total_width; i++)); do printf "─"; done; printf "╯${NC}\n"
	read -p "Appuyez sur une touche pour continuer..." -n1 -s
	# Retour au menu principal
	main_menu
}

main_menu() {
	loading_bar "Chargement du panel IriX..."
	sleep 1
	while true; do
		echo -e "\n
							${CYAN}╭─────── Menu Principal - $(basename ${bot[name]}) ─────────╮${NC}
							${CYAN}│${NC} 0) Installation $(basename ${bot[name]})			${CYAN}│${NC}
							${CYAN}│${NC} 1) Information générale du programme	${CYAN}│${NC}
							${CYAN}│${NC} 2) Vérifier les mises à jour    	${CYAN}│${NC}
							${CYAN}│${NC} 3) Réinstaller le programme     	${CYAN}│${NC}
							${CYAN}│${NC} 4) Désinstaller complètement    	${CYAN}│${NC}
							${CYAN}│${NC} 5) Aide Globale du programme		${CYAN}│${NC}
							${CYAN}│${NC} 6) Quitter 				${CYAN}│${NC}
							${CYAN}╰───────────────────────────────────────╯${NC}"

		read -rp "Veuillez choisir un choix : " choice
		case "$choice" in
			0) MAKEINSTALL ;;
			1) info_gene_panel ;;
			2) upgrade_program ;;
			3) log_warn "Maintenance ! Réinstallation du programme..."; sleep 1; clear ;;
			4) uninstall_program ;;
			5) show_help ;;
			6) log_info "Fermeture du menu principal."; break ;;
			*) log_warn "Choix invalide. Veuillez réessayer."; sleep 1 ;;
		esac
	done
}

case "${1:-}" in
	help) show_help ;;
	start) log_warn "Maintenance ! Réinstallation du programme..." ;;
	upgrade) log_warn "Maintenance ! Réinstallation du programme..." ;;
	uninstall) log_warn "Maintenance ! Réinstallation du programme..." ;;
	info) log_warn "Maintenance ! Réinstallation du programme..." ;;
	*) INSTALL ;;
esac