#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Update manager — sans git, sans compilation
###############################################################################

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$BASE_DIR/config.sh"
source "$BASE_DIR/state.sh"

load_paths
state_init

###############################################################################
# Configuration update
###############################################################################

UPDATE_URL="https://github.com/servus033-cloud/Overtchat/update.json"
TMP_UPDATE_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_UPDATE_DIR"
}
trap cleanup EXIT

###############################################################################
# Fonctions
###############################################################################

fetch_update_info() {
    echo "[update] Récupération des informations de mise à jour..."
    curl -fsSL "$UPDATE_URL" -o "$TMP_UPDATE_DIR/update.json"
}

check_update_available() {
    INSTALLED_VERSION=$(version_get '.installed')
    LATEST_VERSION=$(jq -r '.latest' "$TMP_UPDATE_DIR/update.json")

    [[ "$INSTALLED_VERSION" == "null" ]] && return 0
    [[ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]
}

download_update() {
    ARCHIVE_URL=$(jq -r '.url' "$TMP_UPDATE_DIR/update.json")
    EXPECTED_SHA=$(jq -r '.sha256' "$TMP_UPDATE_DIR/update.json")

    ARCHIVE_PATH="$TMP_UPDATE_DIR/update.tar.gz"

    echo "[update] Téléchargement $ARCHIVE_URL"
    curl -fsSL "$ARCHIVE_URL" -o "$ARCHIVE_PATH"

    echo "[update] Vérification checksum..."
    echo "$EXPECTED_SHA  $ARCHIVE_PATH" | sha256sum -c -
}

extract_update() {
    echo "[update] Extraction de l’update..."
    mkdir -p "$TMP_UPDATE_DIR/extracted"
    tar -xzf "$TMP_UPDATE_DIR/update.tar.gz" -C "$TMP_UPDATE_DIR/extracted"
}

run_update() {
    echo "[update] Lancement de l’installateur en mode update"
    export UPDATE_MODE=true

    "$TMP_UPDATE_DIR/extracted/overtchat/installer/install.sh" update all
}

###############################################################################
# Flux principal
###############################################################################

main() {
    fetch_update_info

    if ! check_update_available; then
        echo "[update] Overtchat est déjà à jour"
        exit 0
    fi

    LATEST_VERSION=$(jq -r '.latest' "$TMP_UPDATE_DIR/update.json")
    echo "[update] Nouvelle version disponible : $LATEST_VERSION"

    download_update
    extract_update
    run_update

    mark_version_installed "$LATEST_VERSION"

    echo "[update] Mise à jour terminée"
}

main "$@"