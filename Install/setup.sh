#!/usr/bin/env bash

[[ "$1" == "--debug" ]] && set -xeuo pipefail || {
    set -euo pipefail
} 

echo "Initialisation en cours..."

IFS=$'\n\t'

# -----------------------------
# Couleurs (fiables)
# -----------------------------
RED=$'\033[0;31m'         # Rouge
BLUE=$'\033[0;34m'        # Bleue
YELLOW=$'\033[1;33m'      # Jaune
GREEN=$'\033[0;32m'       # Vert
PINK=$'\033[0;35m'        # Rose / Mauve
PINK_BRIGHT=$'\033[1;35m' # Rose vif
MAUVE=$'\033[38;2;216;157;255m' # Mauve 24-bit (si support)
NC=$'\033[0m'              # Reset color

accept="${GREEN}Accept :${NC}"
refus="${RED}Refuser :${NC}"
info="${BLUE}Informations :${NC}"
quest="${YELLOW}Question :${NC}"

# -----------------------------
# Variables d'environnement
# -----------------------------

# Initialisation Json
cat > /tmp/overtchat_install_state.json <<'EOF'
{
    "service": 0,
    "serveur": 0,
    "git": 0
}
EOF

# Variables principales pour Json
cat > /tmp/overtchat_install_var.json <<'EOF'
{
    "INSTALL_TMP": /tmp/.Overtchat,
    "INSTALL_BRANCH": main,
    "INSTALL_CONFIG": $HOME/.config~overtchat,
    "INSTALL_DEFAUT": $HOME,
    "INSTALL_HOME": $INSTALL_DEFAUT/Service-Overtchat,
    "INSTALL_SERVER": $INSTALL_DEFAUT/Serveur-Overtchat,
    "INSTALL_BIN": $INSTALL_HOME/bin/Lib,
    "REPO_URL": https://github.com/servus033-cloud/Overtchat.git,
    "MAKEFILE": $INSTALL_TMP/Install/MAKEFILE,
    "MAKEVAR": release,
    "key_api": "44c63e560d1dab5208bb507c8126cbb5204e569b5b85db0adb67b8fbcaf5755b"
}
EOF
eval "$(jq -r 'to_entries|map("export \(.key)=\(.value|tostring)")|.[]' /tmp/overtchat_install_var.json)"

# Nettoyage
rm -f /tmp/overtchat_install_var.json

# -----------------------------
# État interne (runtime)
# -----------------------------
STATE_SERVICE=0
STATE_SERVEUR=0
STATE_GIT=0
STATE_CONFIG=0

# -----------------------------
# Helpers
# -----------------------------
err() { printf "%b\n" "${refus} $*${NC}" >&2; }
infof() { printf "%b\n" "${info} $*${NC}"; }
ok() { printf "%b\n" "${accept} $*${NC}"; }

# -----------------------------
# Pré-requis & self-fix
# -----------------------------
synx=$(find "$HOME" -type f -name "$(basename "$0")" -print -quit 2>/dev/null || true)
if [[ -n "$synx" && ! -x "$synx" ]]; then
    chmod +x "$synx"
    exec "$synx" "$@"
    exit 0
fi

prompt_continue() {
    echo
    read -rp "$info Appuyez sur Entrée pour continuer ou N pour quitter : " -n1 resp || true
    echo
    if [[ "$resp" =~ ^[Nn]$ ]]; then
        echo "Abandon."; exit 0
    fi
}

if ! command -v msmtp &>/dev/null; then
    err "[ msmtp ] Package non installé. Souhaité vous l'installé ? ( access root obligatoire ! )" >&2
    prompt_continue
    if ! sudo apt-get update; then
        err "Impossible de charger Update !"
        exit 1
    fi

    if ! sudo apt install msmtp; then
        err "Impossible d'installer le package"
        exit 1
    fi    
fi

command_exists() { command -v "$1" >/dev/null 2>&1; }

prompt_yn() {
    # usage: prompt_yn "Message ? (Y/N)"
    local prompt_msg="$1"
    while true; do
        read -rp "$prompt_msg" -n1 answer
        echo
        case "$answer" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *) printf "%b\n" "${info} Répondez par Y ou N." ;;
        esac
    done
}

# -----------------------------
# Chargement configuration
# -----------------------------
load_config() {
    local conf_path
    conf_path=$(find "$INSTALL_HOME/Conf" -type f -name "overtchat.conf" -print -quit 2>/dev/null || true)

    if [[ -z "$conf_path" ]]; then
        err "Fichier de configuration introuvable. Veuillez installer correctement le programme."
        return 1
    fi

    # shellcheck disable=SC1090
    if ! source "$conf_path"; then
        err "Erreur : le fichier de configuration contient une erreur."
        return 1
    fi

    return 0
}

# -----------------------------
# Validation e-mail
# -----------------------------
validate_email() {
    local email="$1"

    [[ -z "$email" ]] && { err "L'adresse email ne peut pas être vide."; return 1; }

    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        err "Format email invalide."
        return 1
    fi

    local domain
    domain="${email##*@}"

    if command_exists dig; then
        if ! dig +short MX "$domain" | grep -q . && ! dig +short A "$domain" | grep -q .; then
            err "Le domaine '$domain' semble ne pas exister ou n'a pas d'enregistrements DNS valides."
            return 1
        fi
    else
        infof "Impossible de vérifier le domaine (dig non installé). Vérification DNS sautée.";
    fi

    return 0
}

# -----------------------------
# Affichage principal
# -----------------------------
show_panel() {
    local mode="${1:-}"

    clear
    cat <<EOF
${BLUE}────────────────────────────────────────────${NC}
${BLUE}   Panel Information — Service-Overtchat    ${NC}
${BLUE}────────────────────────────────────────────${NC}

EOF

    if [[ "$mode" == "help" ]]; then
        show_help
    else
        show_commands
    fi
}

# -----------------------------
# Commandes disponibles (court)
# -----------------------------
show_commands() {
    cat <<EOF
${YELLOW}Commandes disponibles :${NC}

  ${GREEN}install${NC}    Installer Service-Overtchat / Serveur
  ${MAUVE}config${NC}     Générer le fichier de configuration
  ${PINK}update${NC}     Vérifier / appliquer les mises à jour
  ${RED}delete${NC}     Désinstaller Service / Serveur
  ${YELLOW}init${NC}       Réinitialiser le dépôt Git
  ${GREEN}statut${NC}     Afficher l'état du programme
  ${BLUE}help${NC}       Afficher l'aide détaillée

${YELLOW}Syntaxe :${NC}
  ${GREEN}${0}${NC} <commande> [options]

Tapez ${BLUE}--help${NC} pour plus de détails.
EOF
}

# -----------------------------
# Aide détaillée
# -----------------------------
show_help() {
    cat <<EOF
${YELLOW}Aide détaillée — Commandes :${NC}

${GREEN}--install <service | server | all>${NC}
  Installe Service-Overtchat, le Serveur ou les deux.

${MAUVE}--config${NC}
  Lance la configuration interactive et génère les fichiers nécessaires.

${PINK}--update [-y | --dry-run]${NC}
  Vérifie et applique les mises à jour depuis le dépôt Git.
  -y         : mise à jour automatique sans confirmation
  --dry-run  : simulation sans modification

${RED}--delete <service | server | all>${NC}
  Désinstalle le ou les composants sélectionnés.

${YELLOW}--init${NC}
  Réinitialise le dépôt Git local en cas de problème.

${GREEN}--statut [--json]${NC}
  Affiche l'état du programme et des composants.

${BLUE}--help${NC}
  Affiche cette aide détaillée.

${YELLOW}Exemples :${NC}
  ${GREEN}${0}${NC} --config
  ${GREEN}${0}${NC} --install service
  ${GREEN}${0}${NC} --update -y
  ${GREEN}${0}${NC} --delete all
EOF
}

show_help_install() {
cat <<EOF
${GREEN}--install <service | server | all>${NC}

Installe les composants du programme.

  service   Installe Service-Overtchat
  server    Installe Serveur-Overtchat
  all       Installe Service + Serveur

Exemples :
  ${0} --install service
  ${0} --install all
EOF
}

show_help_update() {
cat <<EOF
${PINK}--update [-y | --dry-run]${NC}

Met à jour le programme depuis le dépôt Git.

Options :
  -y           Mise à jour automatique (sans confirmation)
  --dry-run    Simulation de la mise à jour

Exemples :
  ${0} --update
  ${0} --update -y
  ${0} --update --dry-run
EOF
}

show_help_delete() {
cat <<EOF
${RED}--delete <service | server | all>${NC}

Désinstalle les composants du programme.

  service   Supprime uniquement Service-Overtchat
  server    Supprime uniquement Serveur-Overtchat
  all       Supprime Service + Serveur + dépôt Git

Exemples :
  ${0} --delete service
  ${0} --delete all
EOF
}

show_help_config() {
cat <<EOF
${MAUVE}--config${NC}

Lance la configuration interactive.
Génère :
  - config.json (source de vérité)
  - overtchat.conf (compatibilité Bash)

Exemple :
  ${0} --config
EOF
}

show_help_statut() {
cat <<EOF
${GREEN}--statut [--json]${NC}

Affiche l'état du programme.

Options :
  --json   Sortie machine-lisible (JSON)

Exemples :
  ${0} --statut
  ${0} --statut --json
EOF
}

show_help_json() {
cat <<'EOF'
{
  "commands": {
    "install": {
      "usage": "--install <service|server|all>",
      "description": "Installe les composants"
    },
    "update": {
      "usage": "--update [-y|--dry-run]",
      "description": "Met à jour le programme"
    },
    "delete": {
      "usage": "--delete <service|server|all>",
      "description": "Désinstalle les composants"
    },
    "config": {
      "usage": "--config",
      "description": "Configuration interactive"
    },
    "statut": {
      "usage": "--statut [--json]",
      "description": "Affiche l'état du programme"
    }
  }
}
EOF
}

install_server() {
    # Pré-checks
    if [[ -d "$SERVER_HOME" ]]; then
        err "Serveur-Overtchat déjà installé"
        return 1
    fi

    if [[ ! -d "$INSTALL_TMP/Serveur-Overtchat" ]]; then
        err "Sources Serveur-Overtchat introuvables"
        return 1
    fi

    infof "Installation du Serveur-Overtchat..."

    # Création du dossier serveur
    mkdir -p "$SERVER_HOME" || {
        err "Impossible de créer $SERVER_HOME"
        return 1
    }

    # Déploiement
    if ! cp -a "$INSTALL_TMP/Serveur-Overtchat/." "$SERVER_HOME/"; then
        err "Erreur lors du déploiement du serveur"
        rm -rf "$SERVER_HOME"
        return 1
    fi

    # Permissions scripts serveur
    if [[ -d "$SERVER_HOME/bin" ]]; then
        find "$SERVER_HOME/bin" -type f -name "*.sh" -exec chmod +x {} \;
    fi

    ok "Serveur-Overtchat installé avec succès"
    return 0
}

install_service() {
    case service in
        service) : ;;
    esac
}

# -----------------------------
# Installation serveur / service
# -----------------------------
setup_serv() {
    if [[ ${1:-} == "" ]]; then
        err "Veuillez spécifier le composant à installer (service | server | all)."
        return 1
    fi
    while true; do
        case "$1" in
            service)
                # ─────────────────────────────
                # Pré-checks
                # ─────────────────────────────
                if [[ -d "$INSTALL_HOME" ]]; then
                    err "Service déjà installé"
                    return 1
                fi

                if [[ -z "$REPO_URL" || -z "$INSTALL_BRANCH" ]]; then
                    err "Configuration Git invalide"
                    return 1
                fi

                prompt_continue
                infof "Installation du service en cours..."

                # ─────────────────────────────
                # Clonage Git
                # ─────────────────────────────
                if [[ -e "$INSTALL_TMP" ]]; then
                    err "Répertoire temporaire déjà présent : $INSTALL_TMP"
                    err "Nettoyez-le avant de relancer l'installation"
                    return 1
                fi

                infof "Clonage du dépôt ($INSTALL_BRANCH)..."
                if ! git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"; then
                    err "Erreur lors du clonage du dépôt Git"
                    rm -rf "$INSTALL_TMP"
                    return 1
                fi

                # ─────────────────────────────
                # Permissions des scripts
                # ─────────────────────────────
                infof "Vérification des scripts exécutables..."

                make_executable() {
                    local dir="$1"

                    if [[ ! -d "$dir" ]]; then
                        err "Répertoire manquant : $dir"
                        return 1
                    fi

                    local files
                    files=$(find "$dir" -type f -name "*.sh" 2>/dev/null)

                    if [[ -z "$files" ]]; then
                        err "Aucun script .sh trouvé dans $dir"
                        return 1
                    fi

                    chmod +x $files
                    return 0
                }

                make_executable "$INSTALL_TMP/Install/bin" || return 1
                make_executable "$INSTALL_TMP/Service-Overtchat/Lib" || return 1

                # ─────────────────────────────
                # Compilation
                # ─────────────────────────────
                if [[ ! -f "$MAKEFILE" ]]; then
                    err "MAKEFILE introuvable : $MAKEFILE"
                    rm -rf "$INSTALL_TMP"
                    return 1
                fi

                infof "Compilation en cours..."
                if ! make -f "$MAKEFILE" "$MAKEVAR"; then
                    err "Erreur lors de la compilation"
                    rm -rf "$INSTALL_TMP"
                    return 1
                fi
                ok "Compilation réussie"

                # ─────────────────────────────
                # Déploiement
                # ─────────────────────────────
                ARCHIVE="$HOME/Service-Overtchat.tar.gz"

                if [[ ! -f "$ARCHIVE" ]]; then
                    err "Archive générée introuvable : $ARCHIVE"
                    rm -rf "$INSTALL_TMP"
                    return 1
                fi

                infof "Déploiement de l'archive..."
                if ! tar -xzf "$ARCHIVE" -C "$HOME/"; then
                    err "Erreur lors de l'extraction de l'archive"
                    rm -rf "$ARCHIVE" "$INSTALL_TMP"
                    return 1
                fi

                rm -f "$ARCHIVE"

                ok "Déploiement terminé avec succès"

                # ─────────────────────────────
                # Post-install
                # ─────────────────────────────
                ok "Installation du service terminée avec succès"
                sleep 2
                clear

                if [[ -x "$INSTALL_BIN/setup-overtchat" ]]; then
                    exec "$INSTALL_BIN/setup-overtchat"
                else
                    warn "setup-overtchat introuvable ou non exécutable"
                fi
            ;;
            server)
                prompt_continue

                # Clonage requis si pas déjà présent
                if [[ ! -d "$INSTALL_TMP/.git" ]]; then
                    infof "Clonage du dépôt..."
                    if ! git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"; then
                        err "Erreur lors du clonage du dépôt"
                        return 1
                    fi
                fi

                install_server || return 1

                ok "Installation Serveur-Overtchat terminée"
                break
            ;;
            all)
                prompt_continue

                infof "Installation complète : Service + Serveur"

                # Installation Service
                install_service || {
                    err "Échec installation Service-Overtchat"
                    return 1
                }

                # Installation Serveur
                install_server || {
                    err "Échec installation Serveur-Overtchat"
                    return 1
                }

                ok "Installation complète terminée avec succès"
                break
            ;;
            *)
                err "Fonction inconnu"
            ;;
        esac
    done
}

# -----------------------------
# Update / upgrade
# -----------------------------
do_update() {
    local auto="$1"
    local dryrun="$2"   # 1 = dry-run

    if ! load_config; then
        err "Configuration invalide. Mise à jour annulée."
        return 1
    fi

    if [[ ! -d "$INSTALL_TMP/.git" ]]; then
        err "Dépôt Git introuvable dans $INSTALL_TMP"
        return 1
    fi

    cd "$INSTALL_TMP" || {
        err "Impossible d'accéder à $INSTALL_TMP"
        return 1
    }

    # Dépôt propre obligatoire
    if ! git diff --quiet || ! git diff --cached --quiet; then
        err "Le dépôt contient des modifications locales"
        return 1
    fi

    infof "Vérification des mises à jour..."

    # Version installée (locale)
    installed_version=$(get_git_version 2>/dev/null || echo "unknown")

    # Version distante (dernière officielle)
    git fetch origin "$INSTALL_BRANCH" --tags >/dev/null 2>&1

    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)
    if [[ -z "$latest_tag" ]]; then
        err "Aucun tag disponible sur le dépôt"
        return 1
    fi
    latest_version="${latest_tag#v}"

    infof "Version installée : $installed_version"
    infof "Dernière version   : $latest_version"

    if [[ "$installed_version" == "$latest_version" ]]; then
        ok "Déjà à jour"
        return 0
    fi

    if [[ "$dryrun" -eq 1 ]]; then
        infof "[DRY-RUN] Mise à jour requise"
        infof "[DRY-RUN] Version installée : $installed_version"
        infof "[DRY-RUN] Version disponible : $latest_version"
        return 0
    fi

    write_version_json

    # Confirmation utilisateur si non-auto
    if [[ "$auto" -ne 1 ]]; then
        if ! prompt_yn "$quest Voulez-vous mettre à jour maintenant ? (Y/N) : "; then
            ok "Mise à jour annulée par l'utilisateur."
            return 0
        fi
    fi

    # Sauvegarde config
    backup_conf="$INSTALL_HOME/Conf/overtchat.conf.bak.$(date +%s)"
    cp -a "$INSTALL_HOME/Conf/overtchat.conf" "$backup_conf"

    infof "Application de la mise à jour..."

    if ! git reset --hard "origin/$INSTALL_BRANCH"; then
        err "Échec de la mise à jour. Restauration."
        git reset --hard HEAD@{1} || true
        return 1
    fi

    now=$(date '+%Y-%m-%d %H:%M:%S')

    sed -i \
        -e "s|^numeric\[\"version\"\]=.*|numeric[\"version\"]=\"$latest_version\"|" \
        -e "s|^numeric\[\"build\"\]=.*|numeric[\"build\"]=\"$now\"|" \
        -e "s|^numeric\[\"check\"\]=.*|numeric[\"check\"]=\"$now\"|" \
        "$INSTALL_HOME/Conf/overtchat.conf"

    ok "Mise à jour terminée vers la version $latest_version"
    infof "Sauvegarde configuration : $backup_conf"

    return 0
}

update() {
    local auto=0
    local dryrun=0

    if [[ ! -f "$INSTALL_CONFIG" && ! -d "$INSTALL_HOME" ]]; then 
        err "Programme non installé ou erroné"
        return 1
    fi

    [[ "${2-}" == "-y" ]] && auto=1
    [[ "${2-}" == "--dry-run" ]] && dryrun=1
    [[ "${3-}" == "--dry-run" ]] && dryrun=1

    do_update "$auto" "$dryrun"
}

# -----------------------------
# Build (helper)
# -----------------------------
setup_build() {
    if [[ ! -d "$INSTALL_TMP" ]]; then
        if ! git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"; then
            err "Erreur lors du clonage"; return 1
        fi
    fi
    setup_serv
}

check_only() {
    collect_status
    load_expected_state

    if [[ "$EXPECT_SERVICE" -ne "$STATE_SERVICE" ]]; then
        return 1
    fi
    if [[ "$EXPECT_SERVEUR" -ne "$STATE_SERVEUR" ]]; then
        return 1
    fi
    if [[ "$EXPECT_GIT" -ne "$STATE_GIT" ]]; then
        return 1
    fi

    return 0
}

repair_service() {
    infof "Réparation : installation du service"
    setup_serv service
}

repair_git() {
    infof "Réparation : initialisation du dépôt Git"
    rm -rf "$INSTALL_TMP"
    git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"
}

repair_from_state() {
    collect_status
    load_expected_state

    # Service attendu mais absent
    if [[ "$EXPECT_SERVICE" -eq 1 && "$STATE_SERVICE" -eq 0 ]]; then
        repair_service
    fi

    # Git attendu mais absent
    if [[ "$EXPECT_GIT" -eq 1 && "$STATE_GIT" -eq 0 ]]; then
        repair_git
    fi

    # Serveur (placeholder)
    if [[ "$EXPECT_SERVEUR" -eq 1 && "$STATE_SERVEUR" -eq 0 ]]; then
        err "Réparation serveur non implémentée"
    fi

    ok "Réparation terminée"
}

# -------------------
#       GIT 
# -------------------
get_git_version() {
    cd "$INSTALL_TMP" || return 1

    git fetch --tags origin >/dev/null 2>&1 || true

    local tag
    tag=$(git describe --tags --abbrev=0 2>/dev/null) || return 1

    echo "${tag#v}"
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local regex="$3"
    local result

    while true; do
        read -rp "$prompt" result
        [[ -z "$result" && -n "$default" ]] && result="$default"

        if [[ -z "$regex" || "$result" =~ $regex ]]; then
            echo "$result"
            return 0
        fi

        err "Entrée invalide, veuillez réessayer."
    done
}

yn_to_bool() {
    [[ "$1" =~ ^[Yy]$ ]] && echo 1 || echo 0
}

get_public_ip() {
    curl -fs --max-time 3 https://ifconfig.co 2>/dev/null || echo "unknown"
}

load_json_config() {
    CONFIG_JSON="$INSTALL_HOME/Conf/config.json"

    if [[ ! -f "$CONFIG_JSON" ]]; then
        err "Configuration JSON introuvable"
        return 1
    fi

    service_enabled=$(jq -r '.features.service' "$CONFIG_JSON")
    server_enabled=$(jq -r '.features.serveur' "$CONFIG_JSON")
}

delete_with_progress() {
    local dir="$1"

    [[ ! -d "$dir" ]] && return 0

    mapfile -t items < <(find "$dir" -mindepth 1 2>/dev/null)
    local total=${#items[@]}
    (( total == 0 )) && return 0

    infof "Suppression de $dir ($total éléments)..."

    local count=0 percent
    for item in "${items[@]}"; do
        rm -rf "$item" 2>/dev/null
        ((count++))
        percent=$(( count * 100 / total ))
        printf "\rProgression : [%-50s] %d%%" \
            "$(printf '%0.s#' $(seq 1 $((percent / 2))))" "$percent"
    done
    printf "\n"

    rm -rf "$dir" 2>/dev/null
}

uninstall_service() {
    infof "Désinstallation Service-Overtchat..."

    [[ -d "$INSTALL_HOME" ]] || {
        warn "Service-Overtchat non présent"
        return 0
    }

    delete_with_progress "$INSTALL_HOME"

    ok "Service-Overtchat désinstallé"
}

uninstall_server() {
    infof "Désinstallation Serveur-Overtchat..."

    [[ -d "$INSTALL_SERVER" ]] || {
        warn "Serveur-Overtchat non présent"
        return 0
    }

    delete_with_progress "$INSTALL_SERVER"

    ok "Serveur-Overtchat désinstallé"
}

uninstall_git() {
    [[ -d "$INSTALL_TMP" ]] && delete_with_progress "$INSTALL_TMP"
}

# -----------------------------
# Main: parsing & flow
# -----------------------------
main() {
    if ! command_exists git; then
        err "Git n'est pas installé. Impossible de lancer le programme. Installez 'git'."; exit 1
    fi

    if [[ ${#@} -eq 0 ]]; then
        show_panel
        return 0
    fi

    case "$1" in
        --install)
            if [[ ! -f "$INSTALL_CONFIG" ]]; then
                err "Veuillez configurer le programme avant de lancer l'installation." \
                "${YELLOW}Syntaxe :${NC} $0 --config"; return 1
            fi
            if [[ "${2-}" == "" ]]; then
                err "Veuillez choisir le programme à installer." \
                "${YELLOW}Syntaxe :${NC} $0 --install service ${MAUVE}( permet d'installer Service-Overtchat )${NC}" \
                "${YELLOW}Syntaxe :${NC} $0 --install server ${MAUVE}( permet d'installer Serveur-Overtchat )${NC}" \
                "${YELLOW}Syntaxe :${NC} $0 --install all ${MAUVE}( permet d'installer l'ensemble du programme )${NC}"; return 1
            fi
            setup_serv "$2"
            ;;
        --update)
            if [[ ! -f "$INSTALL_CONFIG" && ! -d "$INSTALL_TMP" ]]; then
                err "Programme non installé"; return 1
            fi
            if [[ "${2-}" == "" ]]; then
                update
            else
                update "$2"
            fi
        ;;
        --repair)
            if [[ $EUID -ne 0 ]]; then
                err "Réparation nécessite les droits administrateur"
                exit 1
            fi
            repair_from_state
        ;;
        --delete)
            if [[ ! -d "$INSTALL_HOME" && ! -d "$INSTALL_SERVER" ]]; then
                err "Aucun composant installé"
                return 1
            fi

            load_json_config || return 1

            target="${2:-}"

            case "$target" in
                server)
                    info "Cette action supprimera Serveur-Overtchat"
                    prompt_yn "Confirmez-vous la désinstallation ? (Y/N) : " || exit 0

                    uninstall_server
                ;;

                service)
                    info "Cette action supprimera Service-Overtchat"
                    prompt_yn "Confirmez-vous la désinstallation ? (Y/N) : " || exit 0

                    uninstall_service
                ;;

                all)
                    info "Cette action supprimera Service + Serveur (si présents)"
                    prompt_yn "Confirmez-vous la désinstallation complète ? (Y/N) : " || exit 0

                    uninstall_service
                    uninstall_server
                    uninstall_git
                ;;

                *)
                    err "Syntaxe : $0 --delete <server|service|all>"
                    return 1
                ;;
            esac

            ok "Désinstallation terminée"
        ;;
        --config)
            CONFIG_JSON="$INSTALL_HOME/Conf/config.json"
            LEGACY_CONF="$INSTALL_CONFIG"

            # ─── Vérification config existante ───
            if [[ -f "$CONFIG_JSON" || -f "$LEGACY_CONF" ]]; then
                err "Une configuration existe déjà."
                prompt_continue
                infof "Remplacement de la configuration..."
            fi

            # ─── Saisies utilisateur ───
            mail=$(prompt_input \
                "$quest Veuillez enregistrer un email valide : " \
                "" \
                "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")

            load_source=$(prompt_input \
                "$quest Définir un chemin d'installation par défaut ($HOME/) : " \
                "$HOME" \
                "^$HOME(/.*)?$")

            automail=$(yn_to_bool "$(prompt_input \
                "$quest Activer la gestion auto des emails ? (Y/N) : " \
                "Y" \
                "^[YyNn]$")")

            gitdep=$(yn_to_bool "$(prompt_input \
                "$quest Dépendre du dépôt Git (dev) ? (Y/N) : " \
                "Y" \
                "^[YyNn]$")")

            # ─── Infos système ───
            hostname_fqdn=$(hostname -f 2>/dev/null || hostname)
            local_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "null")
            public_ip=$(get_public_ip)

            mkdir -p "$(dirname "$CONFIG_JSON")"

            # ─── Écriture JSON (SOURCE DE VÉRITÉ) ───
cat > "$CONFIG_JSON" <<EOF
{
    "setup": true,
    "config": true,

    "features": {
        "git": $gitdep,
        "automail": $automail,
        "service": false,
        "serveur": false
    },

    "user": {
        "name": "$USER",
        "home": "$HOME",
        "email": "$mail"
    },

    "system": {
        "hostname": "$hostname_fqdn",
        "local_ip": "$local_ip",
        "public_ip": "$public_ip"
    },

    "install": {
        "load_source": "$load_source"
    }
}
EOF

            chmod 600 "$CONFIG_JSON"
            ok "Configuration JSON enregistrée"

            # ─── Génération conf legacy (compatibilité Bash) ───
cat > "$LEGACY_CONF" <<EOF
    setup=1
    config=1
    git=$gitdep
    serveur=0
    service=0
    automail=$automail

    name=$USER
    home=$HOME
    hostname=$hostname_fqdn
    ip=$local_ip
    mail=$mail
    load_source=$load_source
EOF

            chmod 600 "$LEGACY_CONF"

            # ─── Notification API ───
            if [[ "$automail" -eq 1 ]]; then
                curl -s -X POST "http://service.overtchat.free.fr/api/api.php" \
                    -H "Content-Type: application/json" \
                    -H "X-API-KEY: $API_KEY" \
                    -d "{
                        \"email\": \"$mail\",
                        \"hostname\": \"$hostname_fqdn\",
                        \"public_ip\": \"$public_ip\",
                        \"status\": \"Configuration validée\"
                    }" >/dev/null || err "Échec notification API"
            fi

            infof "Configuration validée. Lancez : $0 --install"
        ;;
        --init)
            if [[ ! -f "$INSTALL_CONFIG" ]]; then
                err "Fichier configuration inexistant"; exit 1
            fi
            
            regex=$(sed -n 's/^git=//p' "$INSTALL_CONFIG")
            if [[ "$regex" -eq "0" ]]; then
                err "Gestion Git non chargé dans la configuration"
                exit 1
            fi
            printf "%s\n" "Initialisation du dépôt Git..."

            [[ -d "$INSTALL_TMP" ]] && rm -rf "$INSTALL_TMP"
            if ! git clone -b "$INSTALL_BRANCH" "$REPO_URL" "$INSTALL_TMP"; then
                printf "%s\n" "Erreur lors du clonage" >&2; return 1
            fi

            printf "%s\n" "Dépôt Git initialisé avec succès."
        ;;
        --help)
            case "${2:-}" in
                install) show_help_install ;;
                update)  show_help_update ;;
                delete)  show_help_delete ;;
                config)  show_help_config ;;
                statut)  show_help_statut ;;
                --json)  show_help_json ;;
                *)       show_panel help ;;
            esac
            exit 0
        ;;

        --statut)
            collect_status
            load_expected_state

            if [[ "${2-}" == "--json" ]]; then
                render_status_json
            else
                render_status_human
            fi
        ;;
        --check)
            check_only && exit 0 || exit 1
        ;;
        *)
            show_panel; ;;
    esac
}

# -----------------------------
#           Entrée
# -----------------------------

collect_status() {
    STATE_SERVICE=0
    STATE_SERVEUR=0
    STATE_GIT=0
    STATE_CONFIG=0

    [[ -d "$INSTALL_HOME" ]] && STATE_SERVICE=1
    [[ -d "$INSTALL_SERVER" ]] && STATE_SERVEUR=1
    [[ -d "$INSTALL_TMP/.git" ]] && STATE_GIT=1
    [[ -f "$INSTALL_CONFIG" ]] && STATE_CONFIG=1
}

compute_global_status() {
    if [[ $STATE_SERVICE -eq 1 && $STATE_CONFIG -eq 1 ]]; then
        echo "ok"
    elif [[ $STATE_SERVICE -eq 0 && $STATE_SERVEUR -eq 0 && $STATE_GIT -eq 0 ]]; then
        echo "absent"
    else
        echo "partial"
    fi
}

compute_component_ok() {
    local expected="$1"
    local actual="$2"

    if [[ "$expected" -eq "$actual" ]]; then
        echo true
    else
        echo false
    fi
}

render_status_human() {
    [[ $STATE_SERVICE -eq 1 ]] && ok "Programme Service-Overtchat installé" || err "Programme Service-Overtchat non installé"
    [[ $STATE_SERVEUR -eq 1 ]] && ok "Programme Serveur-Overtchat installé" || err "Programme Serveur-Overtchat non installé"
    [[ $STATE_GIT -eq 1 ]] && ok "Dépôt Git initialisé" || err "Dépôt Git non initialisé"
    [[ $STATE_CONFIG -eq 1 ]] && ok "Configuration chargée" || err "Aucune configuration effectuée"
}

read_conf_value() {
    local key="$1"
    local file="$INSTALL_CONFIG"

    [[ ! -f "$file" ]] && echo "null" && return

    sed -n "s/^${key}=//p" "$file" | head -n1
}

load_expected_state() {
    EXPECT_SERVICE=$(read_conf_value "service")
    EXPECT_SERVEUR=$(read_conf_value "serveur")
    EXPECT_GIT=$(read_conf_value "git")

    [[ "$EXPECT_SERVICE" != "1" ]] && EXPECT_SERVICE=0
    [[ "$EXPECT_SERVEUR" != "1" ]] && EXPECT_SERVEUR=0
    [[ "$EXPECT_GIT" != "1" ]] && EXPECT_GIT=0
}

# -----------------------------
#           JSON
# -----------------------------

write_version_json() {
    local file="$INSTALL_TMP/state.json"

    cat > "$file" <<EOF
{
  "version": {
    "installed": "$installed_version",
    "latest": "$latest_version",
    "update_available": $([[ "$installed_version" != "$latest_version" ]] && echo true || echo false)
  }
}
EOF
}

render_status_json() {
    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
    latest_version="${latest_tag#v}"
    installed_version=$(get_git_version 2>/dev/null || echo "unknown")
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat <<EOF
{
    "schema": "overtchat-status-v2",
    "generated_at": "$ts",

    "paths": {
        "install_home": "$INSTALL_HOME",
        "install_server": "$INSTALL_SERVER",
        "install_tmp": "$INSTALL_TMP"
    },

    "components": {
        "service": {
            "enabled": $( [[ $EXPECT_SERVICE -eq 1 ]] && echo true || echo false ),
            "installed": $( [[ $STATE_SERVICE -eq 1 ]] && echo true || echo false ),
            "ok": $(compute_component_ok "$EXPECT_SERVICE" "$STATE_SERVICE")
        },
        "serveur": {
            "enabled": $( [[ $EXPECT_SERVEUR -eq 1 ]] && echo true || echo false ),
            "installed": $( [[ $STATE_SERVEUR -eq 1 ]] && echo true || echo false ),
            "ok": $(compute_component_ok "$EXPECT_SERVEUR" "$STATE_SERVEUR")
        },
        "git": {
            "enabled": $( [[ $EXPECT_GIT -eq 1 ]] && echo true || echo false ),
            "ready": $( [[ $STATE_GIT -eq 1 ]] && echo true || echo false ),
            "ok": $(compute_component_ok "$EXPECT_GIT" "$STATE_GIT")
        }
    },

    "config": {
        "present": true,
        "path": "$INSTALL_CONFIG"
    },

    "version": {
        "installed": "$installed_version",
        "latest": "$latest_version",
        "update_available": $([[ "$installed_version" != "$latest_version" ]] && echo true || echo false)
    },

    "global_status": "$(compute_global_status)"
}
EOF
}

main "$@"

exit 0