#!/usr/bin/env bash
set -euo pipefail

ROOT="Overtchat"

echo "[+] Création arborescence Overtchat (PRO)"

# ─── Dossiers ───────────────────────────────────────────────────────────────
mkdir -p \
  "$ROOT/bootstrap" \
  "$ROOT/installer" \
  "$ROOT/builder" \
  "$ROOT/components/service" \
  "$ROOT/components/server" \
  "$ROOT/config" \
  "$ROOT/runtime/logs"

# ─── Bootstrap ──────────────────────────────────────────────────────────────
touch "$ROOT/bootstrap/overtchat-setup"
chmod +x "$ROOT/bootstrap/overtchat-setup"

# ─── Installer ──────────────────────────────────────────────────────────────
for f in install preflight ui config state update repair uninstall status; do
  touch "$ROOT/installer/$f.sh"
  chmod +x "$ROOT/installer/$f.sh"
done

# ─── Builder ────────────────────────────────────────────────────────────────
touch \
  "$ROOT/builder/build.sh" \
  "$ROOT/builder/package.sh" \
  "$ROOT/builder/encrypt.sh" \
  "$ROOT/builder/Makefile" \
  "$ROOT/builder/builder.json"

chmod +x "$ROOT/builder/"*.sh

# ─── Components ─────────────────────────────────────────────────────────────
for c in service server; do
  touch \
    "$ROOT/components/$c/install.sh" \
    "$ROOT/components/$c/uninstall.sh" \
    "$ROOT/components/$c/$c.json"
  chmod +x "$ROOT/components/$c/"*.sh
done

# ─── Config ─────────────────────────────────────────────────────────────────
touch \
  "$ROOT/config/paths.json" \
  "$ROOT/config/defaults.json" \
  "$ROOT/config/schema.json"

# ─── Runtime (vide, généré à l’exécution) ────────────────────────────────────
touch "$ROOT/runtime/.gitkeep"

echo "[✓] Arborescence créée avec succès"
exit 0