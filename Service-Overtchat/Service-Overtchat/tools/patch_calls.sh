#!/usr/bin/env bash
# tools/patch_calls.sh - remplace occurrences de chemins .sh par bin/<name>
# Usage: patch_calls.sh <repo_root> <bin_dir_relative>
set -euo pipefail
IFS=$'\n\t'

REPO_ROOT="${1:-.}"
BIN_DIR_REL="${2:-bin}"   # ex: bin  (sera inséré tel quel dans les fichiers)

echo "Patch: repo=$REPO_ROOT bin_dir=$BIN_DIR_REL"

# Fonction pour patcher un fichier source (path relatif à repo)
patch_one() {
  relpath="$1"    # e.g. Service-Overtchat/Lib/core.sh
  binname="$2"    # e.g. Lib_core
  src_escaped=$(printf '%s\n' "$relpath" | sed -e 's/[\/&]/\\&/g')

  # Patterns simples à remplacer (source, bash, sh, ./path, path)
  # On fera les remplacements directement en perl pour garder multi-line
  find "$REPO_ROOT" -type f \( -name "*.sh" -o -name "*.conf" -o -name "*.service" -o -name "*.txt" -o -name "*.py" \) -print0 \
    | xargs -0 -I{} bash -c '
      f="{}"
      case "$f" in
        *'"$BIN_DIR_REL"'* ) exit 0 ;; # ne pas patcher les binaires
      esac
      tmp="$f.patched.$$"
      cp "$f" "$tmp"
      perl -0777 -pe "'" \
        "s|\\bsource\\s+${src_escaped}\\b|${BIN_DIR_REL}/${binname}|g;" \
        "s|\\bbash\\s+${src_escaped}\\b|${BIN_DIR_REL}/${binname}|g;" \
        "s|\\bsh\\s+${src_escaped}\\b|${BIN_DIR_REL}/${binname}|g;" \
        "s|\\./${src_escaped}|${BIN_DIR_REL}/${binname}|g;" \
        "s|${src_escaped}|${BIN_DIR_REL}/${binname}|g;" \
      "'" -i "$tmp" || true
      if ! cmp -s "$f" "$tmp"; then
        mv "$tmp" "$f"
        echo "Patched: $f"
      else
        rm -f "$tmp"
      fi
    '
}

# On construit la liste à patcher :
# Lib/*.sh
if compgen -G "$REPO_ROOT/Service-Overtchat/Lib/*.sh" >/dev/null 2>&1; then
  for f in "$REPO_ROOT"/Service-Overtchat/Lib/*.sh; do
    rel="${f#$REPO_ROOT/}"
    name="$(basename "$f" .sh)"
    binname="Lib_${name}"
    echo "Mapping: $rel -> ${BIN_DIR_REL}/${binname}"
    patch_one "$rel" "$binname"
  done
fi

# Conf/*.sh
if compgen -G "$REPO_ROOT/Service-Overtchat/Conf/*.sh" >/dev/null 2>&1; then
  for f in "$REPO_ROOT"/Service-Overtchat/Conf/*.sh; do
    rel="${f#$REPO_ROOT/}"
    name="$(basename "$f" .sh)"
    binname="Conf_${name}"
    echo "Mapping: $rel -> ${BIN_DIR_REL}/${binname}"
    patch_one "$rel" "$binname"
  done
fi

# IriX/installirix.sh
if [ -f "$REPO_ROOT/Service-Overtchat/Unix/IriX/installirix.sh" ]; then
  rel="Service-Overtchat/Unix/IriX/installirix.sh"
  echo "Mapping: $rel -> ${BIN_DIR_REL}/IriX_installirix"
  patch_one "$rel" "IriX_installirix"
fi

# setup-overtchat.sh
if [ -f "$REPO_ROOT/Service-Overtchat/setup-overtchat.sh" ]; then
  rel="Service-Overtchat/setup-overtchat.sh"
  echo "Mapping: $rel -> ${BIN_DIR_REL}/setup-overtchat"
  patch_one "$rel" "setup-overtchat"
fi

echo "Patch_calls terminé."
