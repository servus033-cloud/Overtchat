#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../../installer/config.sh"
load_paths

echo "[service] Installation..."

mkdir -p "$SERVICE_HOME"

cp -a "$INSTALL_TMP/Service-Overtchat/." "$SERVICE_HOME/"

chmod +x "$SERVICE_BIN"/*.sh 2>/dev/null || true

state_set "components.service" "installed" true
state_set "components.service" "ok" true
state_set "components.service" "last_action" "\"install\""

echo "[service] Installation terminée"
