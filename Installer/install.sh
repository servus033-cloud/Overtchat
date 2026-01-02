#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Overtchat Installer — Orchestrateur
###############################################################################

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

###############################################################################
# Variables globales de décision
###############################################################################

ACTION="${1:-}"
TARGET="${2:-}"

# ─── Chargement des briques ──────────────────────────────────────────────────
source "$BASE_DIR/config.sh"
source "$BASE_DIR/state.sh"
source "$BASE_DIR/preflight.sh"
source "$BASE_DIR/ui.sh"

load_paths
state_init
preflight_check

###############################################################################
# Dispatcher principal
###############################################################################

main() {
    parse_args "$@"

    case "$ACTION" in
        install)  action_install ;;
        update)   action_update ;;
        delete)   action_delete ;;
        status)   action_status ;;
        *)
            echo "Action invalide"
            exit 1
            ;;
    esac
}

###############################################################################
# Actions
###############################################################################

action_install() {
    case "$TARGET" in
        service)
            install_service
            ;;
        server)
            install_server
            ;;
        all)
            install_service
            install_server
            ;;
        *)
            echo "Cible invalide"
            exit 1
            ;;
    esac
}

action_update() {
    echo "[installer] Mode update"

    export UPDATE_MODE=true
    action_install
}

action_delete() {
    case "$TARGET" in
        service)
            ../components/service/uninstall.sh
            ;;
        server)
            ../components/server/uninstall.sh
            ;;
        all)
            ../components/service/uninstall.sh || true
            ../components/server/uninstall.sh || true
            ;;
        *)
            echo "Cible invalide"
            exit 1
            ;;
    esac
}

action_status() {
    echo "=== Overtchat Status ==="
    jq . "$RUNTIME_STATE"
    echo
    jq . "$RUNTIME_VERSION"
}

###############################################################################
# Installations détaillées
###############################################################################

install_service() {
    echo "[installer] Installation Service-Overtchat"

    if needs_build "service"; then
        echo "[installer] Build requis pour Service"
        ../builder/build.sh
        ../builder/package.sh
        state_set "builder" "last_build" "\"$(date -Is)\""
    fi

    components/service/install.sh

    state_set "components.service" "installed" true
    state_set "components.service" "ok" true
    state_set "components.service" "last_action" "\"install\""
}

install_server() {
    echo "[installer] Installation Serveur-Overtchat"

    components/server/install.sh

    state_set "components.server" "installed" true
    state_set "components.server" "ok" true
    state_set "components.server" "last_action" "\"install\""
}

###############################################################################
# Helpers
###############################################################################

needs_build() {
    local component="$1"
    jq -e ".components.$component.installed == false" "$RUNTIME_STATE" >/dev/null
}

###############################################################################
# Point d’entrée
###############################################################################

main "$@"