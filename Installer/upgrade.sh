#!/usr/bin/env bash

# -----------------------------
# Update / upgrade
# -----------------------------
do_update() {
    local auto="$1"
    local dryrun="$2"   # 1 = dry-run

    if ! load_config; then
        err "Configuration invalide. Mise à jour annulée."
        return 1
    fi

    if [[ ! -d "$INSTALL_TMP/.git" ]]; then
        err "Dépôt Git introuvable dans $INSTALL_TMP"
        return 1
    fi

    cd "$INSTALL_TMP" || {
        err "Impossible d'accéder à $INSTALL_TMP"
        return 1
    }

    # Dépôt propre obligatoire
    if ! git diff --quiet || ! git diff --cached --quiet; then
        err "Le dépôt contient des modifications locales"
        return 1
    fi

    infof "Vérification des mises à jour..."

    # Version installée (locale)
    installed_version=$(get_git_version 2>/dev/null || echo "unknown")

    # Version distante (dernière officielle)
    git fetch origin "$INSTALL_BRANCH" --tags >/dev/null 2>&1

    latest_tag=$(git describe --tags --abbrev=0 2>/dev/null)
    if [[ -z "$latest_tag" ]]; then
        err "Aucun tag disponible sur le dépôt"
        return 1
    fi
    latest_version="${latest_tag#v}"

    infof "Version installée : $installed_version"
    infof "Dernière version   : $latest_version"

    if [[ "$installed_version" == "$latest_version" ]]; then
        ok "Déjà à jour"
        return 0
    fi

    if [[ "$dryrun" -eq 1 ]]; then
        infof "[DRY-RUN] Mise à jour requise"
        infof "[DRY-RUN] Version installée : $installed_version"
        infof "[DRY-RUN] Version disponible : $latest_version"
        return 0
    fi

    write_version_json

    # Confirmation utilisateur si non-auto
    if [[ "$auto" -ne 1 ]]; then
        if ! prompt_yn "$quest Voulez-vous mettre à jour maintenant ? (Y/N) : "; then
            ok "Mise à jour annulée par l'utilisateur."
            return 0
        fi
    fi

    # Sauvegarde config
    backup_conf="$INSTALL_HOME/Conf/overtchat.conf.bak.$(date +%s)"
    cp -a "$INSTALL_HOME/Conf/overtchat.conf" "$backup_conf"

    infof "Application de la mise à jour..."

    if ! git reset --hard "origin/$INSTALL_BRANCH"; then
        err "Échec de la mise à jour. Restauration."
        git reset --hard HEAD@{1} || true
        return 1
    fi

    now=$(date '+%Y-%m-%d %H:%M:%S')

    sed -i \
        -e "s|^numeric\[\"version\"\]=.*|numeric[\"version\"]=\"$latest_version\"|" \
        -e "s|^numeric\[\"build\"\]=.*|numeric[\"build\"]=\"$now\"|" \
        -e "s|^numeric\[\"check\"\]=.*|numeric[\"check\"]=\"$now\"|" \
        "$INSTALL_HOME/Conf/overtchat.conf"

    ok "Mise à jour terminée vers la version $latest_version"
    infof "Sauvegarde configuration : $backup_conf"

    return 0
}