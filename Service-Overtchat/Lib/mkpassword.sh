#!/bin/bash

                                        # ────────────────────────────────── #
                                        #   Création du fichier mkpass.sh
                                        # ────────────────────────────────── #

create_mkpass_sh() {
# Fichier mkpass
if [[ -n "${shell[build_mkpass]+_}" ]]; then
    if [[ ! "$(find "$HOME/${folders[dir_lib]}" -type f -name "$(basename -- "${shell[build_mkpass]}")" -print -quit 2>/dev/null)" ]]; then
        log "Création du fichier $(basename -- "${shell[build_mkpass]}") (Code erreur : 055) [en cours]"
        warn "Création du fichier $(basename -- "${shell[build_mkpass]}") [ en cours... ]"
        sleep 2

    cat >"$HOME/${shell[build_mkpass]}" <<'LOCK'
#!/usr/bin/env bash
generate_password_safe() {
    local length=${1:-16}
    local symbols=${2:-no}

    if ! [[ "$length" =~ ^[0-9]+$ ]] || ((length <= 0)); then
        printf "Invalid length\n" >&2
        return 1
    fi

    if command -v openssl >/dev/null 2>&1; then
        # openssl est souvent disponible et sûr
        local bytes=$(((length * 3 + 3) / 4))
        if [[ "$symbols" == "yes" ]]; then
            # on accepte le base64 filtré, puis on ajoute quelques symboles forcés
            pw="$(openssl rand -base64 "$bytes" | tr -d '/+=' | cut -c1-"$length")"
            # s'assurer d'avoir au moins un symbole
            pw="${pw:0:$((length - 1))}!" # remplace la dernière par '!' — simple mais efficace
            printf "%s\n" "$pw"
        else
            openssl rand -base64 "$bytes" | tr -d '/+=' | cut -c1-"$length" && echo
        fi
    else
        # fallback vers /dev/urandom
        if [[ "$symbols" == "yes" ]]; then
            LC_ALL=C tr -dc 'A-Za-z0-9!@#$%&*()-_=+[]{}:;,./?' </dev/urandom | head -c "$length"
        else
            LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
        fi
        echo
    fi
}
LOCK

        log "Création du fichier $(basename -- "${shell[build_mkpass]}") (Code erreur : 055) [terminé]"
        valid "Création du fichier $(basename -- "${shell[build_mkpass]}") [ terminé ]"
        : $((debug++))

        if [[ ! -x "$HOME/${shell[build_mkpass]}" ]]; then
            chmod +x "$HOME/${shell[build_mkpass]}"
            log "Chmod +x du fichier $(basename -- "${shell[build_mkpass]}") (Code erreur : +055) [validé]"
        fi

    else
        valid "Fichier $(basename -- "${shell[build_mkpass]}") [ actif ]"
        : $((debug++))
    fi
fi
}