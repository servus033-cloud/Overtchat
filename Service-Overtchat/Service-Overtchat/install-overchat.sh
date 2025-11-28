#!/usr/bin/env bash
# install-overtchat.sh - installeur autonome (présent dans le tar.gz)
set -euo pipefail
IFS=$'\n\t'

# paramètres
TARGET_DIR="${TARGET_DIR:-$HOME/Overtchat}"
BIN_SUBDIR="${BIN_SUBDIR:-bin}"
VERSION_FILE="${TARGET_DIR}/VERSION"
LOGFILE="${TARGET_DIR}/install.log"

timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] $*" | tee -a "$LOGFILE"; }

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-Service-Overtchat-archive-or-dir>"
  echo "Ex: $0 ./Service-Overtchat-v1.2.3"
  exit 1
fi

SRC="$1"

log "Début installation. Source: $SRC"
log "Destination: $TARGET_DIR"

# Si SRC est une archive .tar.gz - on extrait temporairement
TMP_EXTRACT=""
if [ -f "$SRC" ] && [[ "$SRC" == *.tar.gz ]]; then
  TMP_EXTRACT="$(mktemp -d)"
  log "Extraction de l'archive dans $TMP_EXTRACT"
  tar -xzf "$SRC" -C "$TMP_EXTRACT"
  # généralement l'archive contient un dossier Service-Overtchat-*
  # on prend le premier dossier trouvé
  SRC_DIR="$TMP_EXTRACT/$(ls "$TMP_EXTRACT" | head -n1)"
else
  SRC_DIR="$SRC"
fi

# Copie propre vers TARGET_DIR
log "Création du répertoire cible"
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"
log "Copie des fichiers..."
cp -a "$SRC_DIR"/* "$TARGET_DIR"/

# Permissions
if [ -d "$TARGET_DIR/$BIN_SUBDIR" ]; then
  chmod -R a+x "$TARGET_DIR/$BIN_SUBDIR" || true
fi

# Version
if [ -f "$TARGET_DIR/VERSION" ]; then
  ver="$(cat "$TARGET_DIR/VERSION")"
  log "Version installée: $ver"
fi

# Nettoyage extraction temporaire
if [ -n "$TMP_EXTRACT" ]; then
  rm -rf "$TMP_EXTRACT"
fi

log "Installation terminée. Binaires: $TARGET_DIR/$BIN_SUBDIR"
echo
echo "Installation complétée. Lance le panel avec:"
echo "   $TARGET_DIR/$BIN_SUBDIR/setup-overtchat"
