#!/usr/bin/env bash
                                        # ────────────────────────────────── #
                                        #   Création du fichier include.sh
                                        # ────────────────────────────────── #

create_include_sh() {
# Fichier include
if [[ ! "$(find "$HOME/Service-Overtchat/Lib" -type f -name "include.sh" -print -quit 2>/dev/null)" ]]; then
    printf "%s\n" "Création du fichier include.sh [ en cours... ]"
    log "Création du fichier include.sh (Code erreur : 048) [en cours]"
    sleep 2
    # Création du fichier
    cat >"$HOME/Service-Overtchat/Lib/include.sh" <<'GLOB'
#!/usr/bin/env bash
# ───────────────────────────────────────────── #
#   Fichier d'inclusion - Service Overtchat
#   Généré automatiquement - Ne pas modifier
# ───────────────────────────────────────────── #

                                        # ──────────────────────────────── #
                                        #   Chargement des fichiers .conf
                                        # ──────────────────────────────── #

conf_dir="$HOME/Service-Overtchat/Conf"

# Vérification du dossier Conf
if [[ ! -d "$conf_dir" ]]; then
    printf "%s\n" "Erreur : Dossier Conf introuvable : $conf_dir"
    exit 1
fi

debug=0
over_conf=""

# Boucle sur tous les .conf du dossier

shopt -s nullglob
for pkg in "$conf_dir"/*.conf; do
    # On source uniquement overtchat.conf
    if [[ "$(basename "$pkg")" == "overtchat.conf" ]]; then
        if ! source "$pkg"; then
            printf "%s\n" "Erreur : Impossible de charger $pkg"
            exit 1
        else
            printf "%s\n" "Chargement $pkg validé"
        fi
    fi
done
shopt -u nullglob

                                        # ─────────────────────────────────────── #
                                        #   Chargement des fichiers .sh dans Lib
                                        # ─────────────────────────────────────── #

lib_dir="$HOME/Service-Overtchat/Lib"

if [[ ! -d "$lib_dir" ]]; then
    printf "%s\n" "Erreur : Dossier Lib introuvable : $lib_dir"
    exit 1
fi

shopt -s nullglob
for pkg in "$lib_dir"/*.sh; do
    base="$(basename "$pkg")"

    # On ignore include.sh
    if [[ "$base" == "include.sh" ]]; then
        continue
    fi

    if ! source "$pkg"; then
        printf "%s\n" "Erreur : Impossible de charger $pkg"
        exit 1
    else
        printf "%s\n" "Chargement $pkg validé"
    fi

done
shopt -u nullglob

GLOB

    chmod +x "$HOME/Service-Overtchat/Lib/include.sh"

    printf "%s\n" "Création du fichier include.sh [ terminé ]"
    log "Création du fichier include.sh (Code erreur : 048) [validé]"
fi
}