#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../installer/config.sh"
load_paths

ARCHIVE="/tmp/Service-Overtchat.tar.gz"

echo "[builder] Packaging..."

tar -czf "$ARCHIVE" -C "$SERVICE_HOME" .
