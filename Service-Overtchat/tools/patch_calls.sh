#!/usr/bin/env bash
# tools_local/patch_calls.sh
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="${1:-.}"
BIN_DIR_REL="${2:-bin}"   # ex: bin

echo "Patch_local: repo=$REPO_ROOT bin_rel=$BIN_DIR_REL"

do_replace() {
  src_rel="$1"      # ex: Service-Overtchat/Lib/core.sh
  dest="$2"         # ex: bin/Lib/Lib_core
  find "$REPO_ROOT" -type f \( -name "*.sh" -o -name "*.conf" -o -name "*.service" -o -name "*.txt" -o -name "*.py" \) -print0 \
    | while IFS= read -r -d '' f; do
        # skip files inside the bin folder we are creating
        case "$f" in
          *"/${BIN_DIR_REL}/"* ) continue ;;
        esac
        # perform a set of safe literal replacements using sed -i
        sed -i -e "s|source[[:space:]]\+${src_rel}|${dest}|g" \
               -e "s|\\.\\s*${src_rel}|${dest}|g" \
               -e "s|bash[[:space:]]\+${src_rel}|${dest}|g" \
               -e "s|sh[[:space:]]\+${src_rel}|${dest}|g" \
               -e "s|\\./${src_rel}|${dest}|g" \
               -e "s|${src_rel}|${dest}|g" "$f" || true
    done
}

# Lib/*.sh
if compgen -G "${REPO_ROOT}/Service-Overtchat/Lib/*.sh" >/dev/null 2>&1; then
  for f in "${REPO_ROOT}"/Service-Overtchat/Lib/*.sh; do
    rel="${f#$REPO_ROOT/}"
    name="$(basename "$f" .sh)"
    dest="${BIN_DIR_REL}/Lib/${name}"
    echo "Mapping: $rel -> $dest"
    do_replace "$rel" "$dest"
  done
fi

# Conf/*.sh
if compgen -G "${REPO_ROOT}/Service-Overtchat/Conf/*.sh" >/dev/null 2>&1; then
  for f in "${REPO_ROOT}"/Service-Overtchat/Conf/*.sh; do
    rel="${f#$REPO_ROOT/}"
    name="$(basename "$f" .sh)"
    dest="${BIN_DIR_REL}/Conf/${name}"
    echo "Mapping: $rel -> $dest"
    do_replace "$rel" "$dest"
  done
fi

# Build/Unix/IriX/installirix.sh
if [ -f "${REPO_ROOT}/Service-Overtchat/Build/Unix/IriX/installirix.sh" ]; then
  rel="Service-Overtchat/Build/Unix/IriX/installirix.sh"
  dest="${BIN_DIR_REL}/IriX/installirix"
  echo "Mapping: $rel -> $dest"
  do_replace "$rel" "$dest"
fi

echo "Patch_local terminé."
