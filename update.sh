#!/usr/bin/env bash
set -e

# ======================================================
#  Script de release Git complet
#  Usage :
#      ./update.sh v2.1.5      → version manuelle
#      ./update.sh patch       → auto-incrémentation
#      ./update.sh minor       → auto-incrémentation
#      ./update.sh major       → auto-incrémentation
# ======================================================

# Couleurs
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[36m"
END="\e[0m"

log() { echo -e "${BLUE}➤${END} $1"; }
ok()  { echo -e "${GREEN}✔${END} $1"; }
err() { echo -e "${RED}✖${END} $1"; }

# ------------------------------------------------------
# 1) Récupération de la version distante la plus élevée
# ------------------------------------------------------
get_latest_tag() {
    git fetch --tags >/dev/null 2>&1 || true
    latest=$(git tag -l "v*" | sort -V | tail -n1)
    echo "${latest:-v0.0.0}"
}

increment_version() {
    local mode="$1"
    local ver="$2"
    local major minor patch
    IFS='.' read -r major minor patch <<<"${ver#v}"

    case "$mode" in
        patch) patch=$((patch + 1)) ;;
        minor) minor=$((minor + 1)); patch=0 ;;
        major) major=$((major + 1)); minor=0; patch=0 ;;
        *)
            err "Mode inconnu : $mode"
            exit 1
            ;;
    esac

    echo "v$major.$minor.$patch"
}

# ------------------------------------------------------
# 2) Détermination de la version cible
# ------------------------------------------------------
if [[ -z "$1" ]]; then
    err "Usage: $0 vX.Y.Z | patch | minor | major"
    exit 1
fi

ARG="$1"
LATEST="$(get_latest_tag)"

if [[ "$ARG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    VERSION="$ARG"
else
    VERSION="$(increment_version "$ARG" "$LATEST")"
fi

log "Dernière version détectée : $LATEST"
ok  "Nouvelle version ciblée : $VERSION"

# ------------------------------------------------------
# 3) Vérification des changements
# ------------------------------------------------------
CHANGES=$(git status --porcelain)

if [[ -z "$CHANGES" ]]; then
    log "Aucun fichier modifié."
    read -p "Créer un tag $VERSION quand même ? (y/N) : " ans
    [[ "$ans" != "y" && "$ans" != "Y" ]] && exit 0
else
    log "Ajout des fichiers modifiés…"
    git add .

    log "Création du commit…"
    git commit -m "Release $VERSION"
    ok "Commit OK"
fi

# ------------------------------------------------------
# 4) Push des commits
# ------------------------------------------------------
log "Push des commits…"
git push
ok "Commits poussés"

# ------------------------------------------------------
# 5) Suppression ancienne version si déjà existante
# ------------------------------------------------------
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    log "Suppression ancien tag local $VERSION…"
    git tag -d "$VERSION"
fi

if git ls-remote --tags origin | grep -q "refs/tags/$VERSION"; then
    log "Suppression ancien tag distant $VERSION…"
    git push origin :refs/tags/"$VERSION"
fi

# ------------------------------------------------------
# 6) Génération du changelog automatique
# ------------------------------------------------------
log "Génération automatique du changelog…"
CHANGELOG=$(git log "$LATEST"..HEAD --pretty=format:"- %s")

if [[ -z "$CHANGELOG" ]]; then
    CHANGELOG="- Mise à jour mineure"
fi

MESSAGE="Release $VERSION

Changelog :
$CHANGELOG
"

# ------------------------------------------------------
# 7) Création du tag annoté
# ------------------------------------------------------
log "Création du tag $VERSION…"
git tag -a "$VERSION" -m "$MESSAGE"
ok "Tag créé"

# ------------------------------------------------------
# 8) Push du tag
# ------------------------------------------------------
log "Push du tag vers GitHub…"
git push origin "$VERSION"
ok "Tag poussé sur GitHub"

# ------------------------------------------------------
# 9) Fin
# ------------------------------------------------------
echo -e "\n${GREEN}🎉 Release $VERSION générée avec succès !${END}"