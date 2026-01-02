#!/usr/bin/env bash
set -euo pipefail

BIN="$1"

[[ -z "$BIN" ]] && {
    echo "Usage: encrypt.sh <binary>"
    exit 1
}

shc -f "$BIN" -o "${BIN}.bin"
