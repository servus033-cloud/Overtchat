#!/usr/bin/env bash
# install-overtchat.sh - installe l'archive / dossier Service-Overtchat vers $HOME/Overtchat
set -euo pipefail
IFS=$'\n\t'

TARGET="${TARGET:-$HOME/Overtchat}"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-extracted-Service-Overtchat-dir-or-archive>"
  exit 1
fi

SRC="$1"

# If archive .tar.gz -> extract to tmpdir
if [ -f "$SRC" ] && [[ "$SRC" == *.tar.gz ]]; then
  TMP="$(mktemp -d)"
  tar -xzf "$SRC" -C "$TMP"
  # take first directory inside
  SRC_DIR="$TMP/$(ls "$TMP" | head -n1)"
else
  SRC_DIR="$SRC"
fi

echo "Installation depuis $SRC_DIR vers $TARGET"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$SRC_DIR"/* "$TARGET"/

# Rendre bin executable
if [ -d "$TARGET/bin" ]; then
  chmod -R a+x "$TARGET/bin" || true
fi

echo "✔ Installation terminée dans $TARGET"
echo "Lance le panel : $TARGET/bin/setup-overtchat"
#!/usr/bin/env bash
# install-overtchat.sh - installe l'archive / dossier Service-Overtchat vers $HOME/Overtchat
set -euo pipefail
IFS=$'\n\t'

TARGET="${TARGET:-$HOME/Overtchat}"

if [ $# -lt 1 ]; then
  echo "Usage: $0 <path-to-extracted-Service-Overtchat-dir-or-archive>"
  exit 1
fi

SRC="$1"

# If archive .tar.gz -> extract to tmpdir
if [ -f "$SRC" ] && [[ "$SRC" == *.tar.gz ]]; then
  TMP="$(mktemp -d)"
  tar -xzf "$SRC" -C "$TMP"
  # take first directory inside
  SRC_DIR="$TMP/$(ls "$TMP" | head -n1)"
else
  SRC_DIR="$SRC"
fi

echo "Installation depuis $SRC_DIR vers $TARGET"

rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$SRC_DIR"/* "$TARGET"/

# Rendre bin executable
if [ -d "$TARGET/bin" ]; then
  chmod -R a+x "$TARGET/bin" || true
fi

echo "✔ Installation terminée dans $TARGET"
echo "Lance le panel : $TARGET/bin/setup-overtchat"
