#!/usr/bin/env bash
set -euo pipefail

### ──────────────── INIT ────────────────
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$BASE_DIR/../config"

PATHS_JSON="$CONFIG_DIR/paths.json"
IRIX_JSON="$CONFIG_DIR/irix.json"

TMP="$(mktemp)"
LOCK="$IRIX_JSON.lock"

GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

### ──────────────── CHECK ────────────────
[[ -f "$PATHS_JSON" ]] || { echo "paths.json manquant"; exit 1; }
[[ -f "$IRIX_JSON" ]] || { echo "irix.json manquant"; exit 1; }

jq empty "$PATHS_JSON" >/dev/null
jq empty "$IRIX_JSON" >/dev/null

### ──────────────── UTILS ────────────────
status() {
  [[ "$1" == "true" ]] && printf "${GREEN}[EXISTANT]${RESET}" \
                        || printf "${RED}[NON EXISTANT]${RESET}"
}

expand_path() {
  eval echo "$1"
}

### ──────────────── INSTALL ────────────────
(
flock -x 200

ROOT_PATH=$(jq -r '.folders.Overtchat.path' "$IRIX_JSON")
ROOT_PATH=$(expand_path "$ROOT_PATH")

# Root
if [[ -d "$ROOT_PATH" ]]; then
  root_exists=true
else
  mkdir -p "$ROOT_PATH"
  root_exists=true
fi

jq --argjson v "$root_exists" \
  '.folders.Overtchat.exists = $v' \
  "$IRIX_JSON" > "$TMP" && mv "$TMP" "$IRIX_JSON"

# Children
jq -r '.folders.Overtchat.children | keys[]' "$IRIX_JSON" |
while read -r child; do
  path="$ROOT_PATH/$child"
  if [[ -d "$path" ]]; then
    exists=true
  else
    mkdir -p "$path"
    exists=true
  fi

  jq --arg c "$child" --argjson v "$exists" \
    '.folders.Overtchat.children[$c].exists = $v' \
    "$IRIX_JSON" > "$TMP" && mv "$TMP" "$IRIX_JSON"
done

# Runtime cmds json
CMDS_PATH=$(jq -r '.database.cmdsbot' "$IRIX_JSON")
CMDS_PATH=$(expand_path "$CMDS_PATH")

if [[ ! -f "$CMDS_PATH" ]]; then
  mkdir -p "$(dirname "$CMDS_PATH")"
  cp "$BASE_DIR/../runtime/cmds_irix.json" "$CMDS_PATH"
  jq '.folders.Overtchat.children.runtime.irix_json.exists = true' \
    "$IRIX_JSON" > "$TMP" && mv "$TMP" "$IRIX_JSON"
fi

# Final state
jq '.complete = true' "$IRIX_JSON" > "$TMP" && mv "$TMP" "$IRIX_JSON"

) 200>"$LOCK"
rm -f "$LOCK"

### ──────────────── DISPLAY ────────────────
echo
echo "STRUCTURE IRIX"
echo "---------------------------------"

root=$(jq -r '.folders.Overtchat.exists' "$IRIX_JSON")
printf "${BLUE}%-15s${RESET} " "Overtchat"
status "$root"
echo

jq -r '.folders.Overtchat.children | to_entries[] | "\(.key) \(.value.exists)"' "$IRIX_JSON" |
while read -r name exists; do
  printf "  ├─ %-12s " "$name"
  status "$exists"
  echo
done

echo
echo -e "${GREEN}✔ Installation IriX terminée${RESET}"
echo
exit 0
