#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../../installer/config.sh"
load_paths

echo "[service] Désinstallation..."

rm -rf "$SERVICE_HOME"

echo "[service] Désinstallé"
