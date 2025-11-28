#!/usr/bin/env bash

                                        # ────────────────────────────────── #
                                        #   Création du fichier sendmails.sh
                                        # ────────────────────────────────── #

create_sendmails_sh() {
if [[ -n "${shell[build_mails]+_}" ]]; then
    if [[ ! "$(find "$HOME/${folders[dir_lib]}" -type f -name "$(basename -- "${shell[build_mails]}")" -print -quit 2>/dev/null)" ]]; then
        log "Création du fichier $(basename -- "${shell[build_mails]}") (Code erreur : 055) [en cours]"
        warn "Création du fichier $(basename -- "${shell[build_mails]}") [ en cours... ]"
        sleep 2

        cat >"$HOME/${shell[build_mails]}" <<'MAIL'
#!/usr/bin/env bash
# Fonction client : build + hash + envoi
send_install_report() {
    local USER_EMAIL="$1"     # optionnel, email de l'utilisateur (consent)
    local INSTALL_STATUS="$2" # "ok" ou "error"
    local LOGFILE="${LOGFILE:-${files[logs]}}"
    local SCRIPT_VERSION="${SCRIPT_VERSION:-v1.0}"
    local REPORT_TO=""
    local FROM=""

    # Défensif : si l'associative array 'over' existe et contient les clés, on les utilise,
    # sinon on prend des variables de repli (over_admin_mail / over_support_mail) ou on laisse vide.
    if [[ -v over[admin_mail] ]]; then
        REPORT_TO="${over[admin_mail]}"
    elif [[ -n "${over_admin_mail:-}" ]]; then
        REPORT_TO="${over_admin_mail}"
    fi

    if [[ -v over[support_mail] ]]; then
        FROM="${over[support_mail]}"
    elif [[ -n "${over_support_mail:-}" ]]; then
        FROM="${over_support_mail}"
    fi

    generate_password_safe() {
        local length=${1:-20}
        LC_ALL=C tr -dc 'A-Za-z0-9!@#$%&*()-_=+[]{}:;,.?/' </dev/urandom | head -c "$length"
        echo
    }

    # Génération mot de passe et hashage (si créer un compte)
    local user_pass hash_pass
    user_pass="$(generate_password_safe 20)"
    # stocke/hash localement, ne jamais l'envoyer en clair
    hash_pass="$(printf '%s' "$user_pass" | sha256sum | awk '{print $1}')"

    # Sauvegarde locale (si besoin) : stocker le hash, pas le mot de passe
    printf "%s\n" "$hash_pass" >>"${HOME}/Service-Overtchat/Build/.overtchat_pass_hashes"
    chmod 600 "${HOME}/Service-Overtchat/Build/.overtchat_pass_hashes"

    # Extrait les dernières lignes de log pour le rapport
    local log_excerpt
    if [[ -f "$LOGFILE" ]]; then
        log_excerpt="$(tail -n 200 "$LOGFILE" | sed 's/^/    /')"
    else
        log_excerpt="(no log file found)"
    fi

    # Récupération IP publique (silencieuse)
    local public_ip
    public_ip="$(curl -fs --max-time 3 https://ifconfig.co 2>/dev/null || echo 'unknown')"

    # Compose le rapport dans un temp file
    local tmpfile
    tmpfile="$(mktemp)" || return 1
    {
        printf "From: %s\n" "$FROM"
        printf "To: %s\n" "$REPORT_TO"
        printf "Subject: Rapport d'installation — %s — %s\n" "$(hostname)" "$(date -Iseconds)"
        printf "MIME-Version: 1.0\n"
        printf "Content-Type: text/plain; charset=UTF-8\n\n"

        printf "Hostname: %s\n" "$(hostname)"
        printf "Public-IP: %s\n" "$public_ip"
        printf "Script-Version: %s\n" "$SCRIPT_VERSION"
        printf "Status: %s\n" "$INSTALL_STATUS"
        printf "User-Hash: %s\n" "$hash_pass"
        [[ -n "$USER_EMAIL" ]] && printf "User-Email: %s\n" "$USER_EMAIL"
        printf "\n--- Logs (dernieres lignes) ---\n%s\n" "$log_excerpt"
    } >"$tmpfile"

    # Envoi via msmtp (configuration /etc/msmtprc ou ~/.msmtprc attendue)
    if command -v msmtp &>/dev/null; then
        msmtp --read-envelope-from --read-recipients <"$tmpfile"
        local rc=$?
        rm -f "$tmpfile"
        return $rc
    else
        rm -f "$tmpfile"
        echo "msmtp non installé" >&2
        return 2
    fi
}
MAIL
        log "Création du fichier $(basename -- "${shell[build_mails]}") (Code erreur : 055) [terminé]"
        valid "Création du fichier $(basename -- "${shell[build_mails]}") [ terminé ]"
        : $((debug++))

        if [[ ! -x "$HOME/${shell[build_mails]}" ]]; then
            chmod +x "$HOME/${shell[build_mails]}"
            log "Chmod +x du fichier $(basename -- "${shell[build_mails]}") (Code erreur : +055) [validé]"
        fi

    else
        valid "Fichier $(basename -- "${shell[build_mails]}") [ actif ]"
        : $((debug++))
    fi
fi
}