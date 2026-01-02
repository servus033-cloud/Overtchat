#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Repair manager — remise en cohérence état / filesystem
###############################################################################

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/config.sh"
source "$BASE_DIR/state.sh"

load_paths
state_init

###############################################################################
# Helpers filesystem
###############################################################################

service_exists() {
    [[ -d "$SERVICE_HOME" ]]
}

server_exists() {
    [[ -d "$SERVER_HOME" ]]
}

###############################################################################
# Repair logique
###############################################################################

repair_service() {
    local installed ok

    installed=$(state_get '.components.service.installed')
    ok=$(state_get '.components.service.ok')

    echo "[repair] Service — state: installed=$installed ok=$ok"

    if [[ "$installed" == "true" && ! service_exists ]]; then
        echo "[repair] Service manquant → réinstallation"
        components/service/install.sh
        mark_component_installed service
        return
    fi

    if [[ "$installed" == "false" && service_exists ]]; then
        echo "[repair] Service présent mais non déclaré → correction état"
        mark_component_installed service
        return
    fi

    if [[ "$installed" == "true" && "$ok" == "false" ]]; then
        echo "[repair] Service marqué KO → réinstallation"
        components/service/install.sh
        mark_component_installed service
        return
    fi

    echo "[repair] Service OK"
}

repair_server() {
    local installed ok

    installed=$(state_get '.components.server.installed')
    ok=$(state_get '.components.server.ok')

    echo "[repair] Serveur — state: installed=$installed ok=$ok"

    if [[ "$installed" == "true" && ! server_exists ]]; then
        echo "[repair] Serveur manquant → réinstallation"
        components/server/install.sh
        mark_component_installed server
        return
    fi

    if [[ "$installed" == "false" && server_exists ]]; then
        echo "[repair] Serveur présent mais non déclaré → correction état"
        mark_component_installed server
        return
    fi

    if [[ "$installed" == "true" && "$ok" == "false" ]]; then
        echo "[repair] Serveur marqué KO → réinstallation"
        components/server/install.sh
        mark_component_installed server
        return
    fi

    echo "[repair] Serveur OK"
}

###############################################################################
# Point d’entrée
###############################################################################

main() {
    echo "=== Overtchat Repair ==="

    repair_service
    repair_server

    echo
    echo "[repair] Vérification terminée"
    state_summary
}

main "$@"
