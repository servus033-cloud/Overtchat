#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Configuration loader — source de vérité passive
###############################################################################

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$BASE_DIR/../config"

PATHS_JSON="$CONFIG_DIR/paths.json"
DEFAULTS_JSON="$CONFIG_DIR/defaults.json"
USER_CONFIG_JSON="$CONFIG_DIR/config.json"

###############################################################################
# Loader principal
###############################################################################

load_paths() {
    [[ -f "$PATHS_JSON" ]] || {
        echo "paths.json introuvable"
        exit 1
    }

    # ─── INSTALL ────────────────────────────────────────────────────────────
    INSTALL_ROOT=$(jq -r '.install.root' "$PATHS_JSON")
    INSTALL_TMP=$(jq -r '.install.tmp' "$PATHS_JSON")

    SERVICE_HOME=$(jq -r '.install.service.home' "$PATHS_JSON")
    SERVICE_BIN=$(jq -r '.install.service.bin' "$PATHS_JSON")
    SERVICE_LIB=$(jq -r '.install.service.lib' "$PATHS_JSON")
    SERVICE_CONF=$(jq -r '.install.service.conf' "$PATHS_JSON")

    SERVER_HOME=$(jq -r '.install.server.home' "$PATHS_JSON")
    SERVER_BIN=$(jq -r '.install.server.bin' "$PATHS_JSON")
    SERVER_CONF=$(jq -r '.install.server.conf' "$PATHS_JSON")

    # ─── RUNTIME ────────────────────────────────────────────────────────────
    RUNTIME_STATE=$(jq -r '.runtime.state' "$PATHS_JSON")
    RUNTIME_VERSION=$(jq -r '.runtime.version' "$PATHS_JSON")
    RUNTIME_LOGS=$(jq -r '.runtime.logs' "$PATHS_JSON")

    # ─── ACTIF ROOT ─────────────────────────────────────────────────────────
    ROOT_UID=$(jq -r '.root.uid' "$PATHS_JSON")
    ROOT_ACCESS=$(jq -r '.root.online' "$PATHS_JSON")
    
    validate_paths
}

###############################################################################
# Defaults & user config
###############################################################################

load_defaults() {
    [[ -f "$DEFAULTS_JSON" ]] || return 0

    BUILD_CHANNEL=$(jq -r '.build.channel // "stable"' "$DEFAULTS_JSON")
    AUTO_UPDATE=$(jq -r '.update.auto // false' "$DEFAULTS_JSON")
}

load_user_config() {
    [[ -f "$USER_CONFIG_JSON" ]] || return 0

    # surcharge contrôlée
    BUILD_CHANNEL=$(jq -r '.build.channel // empty' "$USER_CONFIG_JSON") || true
    AUTO_UPDATE=$(jq -r '.update.auto // empty' "$USER_CONFIG_JSON") || true
}

###############################################################################
# Validation
###############################################################################

validate_paths() {
    local vars=(
        INSTALL_ROOT INSTALL_TMP
        SERVICE_HOME SERVICE_BIN SERVICE_LIB SERVICE_CONF
        SERVER_HOME SERVER_BIN SERVER_CONF
        RUNTIME_STATE RUNTIME_VERSION RUNTIME_LOGS
    )

    for v in "${vars[@]}"; do
        [[ -z "${!v}" || "${!v}" == "null" ]] && {
            echo "Configuration invalide : $v"
            exit 1
        }
    done
    load_defaults
    load_user_config
}

###############################################################################
# Loader global
###############################################################################

load_config() {
    load_paths
    load_defaults
    load_user_config
}
