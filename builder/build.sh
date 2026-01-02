#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../installer/config.sh"
load_paths

echo "[builder] Compilation..."

make -f "$INSTALL_TMP/MAKEFILE" release
