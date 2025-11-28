#!/usr/bin/env bash
                                        # ────────────────────────────────── #
                                        #   Création du fichier sql.sh
                                        # ────────────────────────────────── #

create_sql_sh() {
# Fichier Sql
if [[ -n "${shell[build_sql]+_}" ]]; then
    if [[ ! "$(find "$HOME/${folders[dir_lib]}" -type f -name "$(basename -- "${shell[build_sql]}")" -print -quit 2>/dev/null)" ]]; then
        log "Création du fichier $(basename -- "${shell[build_sql]}") (Code erreur : 056) [en cours]"
        warn "Création du fichier $(basename -- "${shell[build_sql]}") [ en cours... ]"
        sleep 2
        cat >"$HOME/${shell[build_sql]}" <<'SQL'
#!/usr/bin/env bash

# --- Création/initialisation de la base SQL pour Service-Overtchat (avec pwgen) ---
setup_sql() {
    if [[ -n "${files[data_sql]+_}" ]]; then
        if [[ ! -f "${files[data_sql]}]]" ]]; then
            touch "${files[data_sql]}"
        fi
        local conf_file="${files[data_sql]}"
    fi
    std "=== Installation / configuration MariaDB pour Service-Overtchat ==="

    read -rp "Hôte MariaDB (ou 'localhost') [localhost] : " sql_host
    sql_host=${sql_host:-localhost}

    read -rp "Chemin socket MySQL (laisser vide pour TCP) [/var/run/mysqld/mysqld.sock] : " sql_sock
    sql_sock=${sql_sock:-/var/run/mysqld/mysqld.sock}

    read -rp "Nom de la base à créer [overtchat] : " svc_db
    svc_db=${svc_db:-overtchat}

    read -rp "Nom de l'utilisateur service (utilisé par eggdrop/web) [overtchat_user] : " svc_user
    svc_user=${svc_user:-overtchat_user}

    # Mot de passe service (si vide -> on génère avec pwgen)
    read -rp "Mot de passe pour l'utilisateur service (laisser vide pour générer automatiquement) : " svc_pass
    if [[ -z "$svc_pass" ]]; then
        if command -v pwgen &>/dev/null; then
            svc_pass=$(pwgen -s 20 1)
        else
            # fallback sécurisé si pwgen absent
            svc_pass=$(openssl rand -base64 15)
        fi
        printf "%s\n" "Mot de passe généré : " "$svc_pass"
    fi

    # Compte admin pour créer DB / user
    read -rp "Admin DB user pour créer la base (ex: root) [root] : " admin_user
    admin_user=${admin_user:-root}
    read -rsp "Mot de passe admin MySQL pour $admin_user : " admin_pass
    printf "\n"

    read -rp "Nom de la table principale [overtchat_logs] : " svc_table
    svc_table=${svc_table:-overtchat_logs}

    # Construire la commande mysql selon socket ou host (on ne met pas le mot de passe en argv)
    local mysql_admin_cmd
    if [[ -n "$sql_sock" ]] && [[ "$sql_host" == "localhost" ]]; then
        mysql_admin_cmd=(mysql --socket="$sql_sock" -u "$admin_user" --batch --silent)
    else
        mysql_admin_cmd=(mysql -h "$sql_host" -u "$admin_user" --batch --silent)
    fi

    # Test de connexion admin (utilise MYSQL_PWD pour ne pas exposer en argv)
    if ! printf "SELECT 1;\n" | MYSQL_PWD="$admin_pass" "${mysql_admin_cmd[@]}" >/dev/null 2>&1; then
        error "Impossible de se connecter à MariaDB avec les identifiants admin fournis."
        return 1
    fi

    valid "Connexion admin OK — création de la base/utilisateur si besoin..."

    # SQL pour création DB, user, grant et table
    read -r -d '' SQL <<'EOF' || true
CREATE DATABASE IF NOT EXISTS `__DB__` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '__USER__'@'__HOST__' IDENTIFIED BY '__PASS__';
ALTER USER '__USER__'@'__HOST__' IDENTIFIED BY '__PASS__';
GRANT SELECT, INSERT, UPDATE, DELETE ON `__DB__`.* TO '__USER__'@'__HOST__';
FLUSH PRIVILEGES;
USE `__DB__`;
CREATE TABLE IF NOT EXISTS `__TABLE__` (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nick VARCHAR(64) NOT NULL,
    action VARCHAR(64) NOT NULL,
    payload TEXT,
    ts TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
EOF

    # Substitutions sûres (on protège les quotes simples en remplaçant avant)
    local sql_host_for_grant="%"
    # Si l'utilisateur veut limiter à localhost, on met 'localhost'
    if [[ "$sql_host" == "localhost" || "$sql_host" == "127.0.0.1" ]]; then
        sql_host_for_grant="localhost"
    fi

    SQL="${SQL//__DB__/$svc_db}"
    SQL="${SQL//__USER__/$svc_user}"
    SQL="${SQL//__HOST__/$sql_host_for_grant}"
    # On échappe correctement le mot de passe pour l'insérer dans le script SQL
    # Ici on remplace ' par '\'' (méthode simple)
    local esc_pass="${svc_pass//\'/\'\\\'\'}"
    SQL="${SQL//__PASS__/$esc_pass}"
    SQL="${SQL//__TABLE__/$svc_table}"

    # Exécution SQL (encore via MYSQL_PWD pour sécurité)
    export MYSQL_PWD="$admin_pass"
    if ! printf "%s\n" "$SQL" | "${mysql_admin_cmd[@]}"; then
        error "Échec lors de l'exécution des commandes SQL."
        return 1
    fi
    unset MYSQL_PWD

    valid "Base et table créées / mises à jour."

    # Écriture du fichier de conf
    cat >"$conf_file" <<CREATEUSERS
# Ip de connexion Mariadb
sql[hostname]="${sql_host}"
# Login Accés (utilisateur du service)
sql[login]="${svc_user}"
# Password Accés
sql[password]="${svc_pass}"
# Chemin du service socket pour mysql (laisser vide si TCP)
sql[sock]="${sql_sock}"
# Dossier Sql (nom de la base)
sql[database]="${svc_db}"
# Gestion table principale
sql[table]="${svc_table}"
CREATEUSERS

    chmod 600 "$conf_file"
    valid "Fichier de config SQL écrit et protégé : $conf_file"
    : $((debug++))
}

setup_sql "$@"
SQL

        valid "Création du fichier $(basename -- "${shell[build_sql]}") [ terminé ]"
        log "Création du fichier $(basename -- "${shell[build_sql]}") (Code erreur : 056) [terminé]"
        : $((debug++))

        if [[ ! -x "$HOME/${shell[build_sql]}" ]]; then
            chmod +x "$HOME/${shell[build_sql]}"
            log "Chmod du fichier $(basename -- "${shell[build_sql]}") (Code erreur : +056) [validé]"
        fi
    else
        log "Fichier $(basename -- "${shell[build_sql]}") (Code erreur : 056) [actif]"
        valid "Fichier $(basename -- "${shell[build_sql]}") [ actif ]"
        : $((debug++))
    fi
else
    log "Variable shell[build_sql] (Code erreur : 056) [échec]"
fi
}