#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Preflight checks — aucune action destructive
###############################################################################

preflight_check() {
    echo "[preflight] Vérifications système..."

    check_shell
    check_user
    check_os
    check_dependencies
    check_paths
    check_permissions
    check_disk_space
    check_runtime_conflicts

    echo "$(date) [preflight] OK" >> "$RUNTIME_LOGS/logs.txt"
}

###############################################################################
# Vérifications détaillées
###############################################################################

check_shell() {
    [[ -n "${BASH_VERSION:-}" ]] || {
        echo "Bash requis"
        echo "$(date) [Bash requis] ERROR" >> "$RUNTIME_LOGS/logs.txt"
        exit 1
    }
}

check_user() {
    if [[ "$ROOT_ACCESS" -eq 1 ]]; then
        if [[ "$EUID" -ne 0 ]]; then
            echo "Ce programme doit être exécuté en root !"
            echo "$(date) [EUID] Access root ERROR" >> "$RUNTIME_LOGS/logs.txt"
            exit 1
        fi
    fi
}

check_os() {
    [[ -f /etc/os-release ]] || {
        echo "OS non supporté"
        echo "$(date) [OS NULL] ERROR" >> "$RUNTIME_LOGS/logs.txt"
        exit 1
    }
}

check_dependencies() {
    local deps=(
        jq
        curl
        tar
        make
        sha256sum
    )

    for d in "${deps[@]}"; do
        command -v "$d" >/dev/null 2>&1 || {
            echo "Dépendance manquante : $d. Installation via apt.."
            if ! sudo apt update && sudo apt install $d -y; then
                echo "Erreur avec les droit administrateur !"
                echo "$(date) [Sudo Apt] ERROR" >> "$RUNTIME_LOGS/logs.txt"
                exit 1
            fi
        }
    done
}

check_paths() {
    local paths=(
        "$INSTALL_ROOT"
        "$INSTALL_TMP"
        "$SERVICE_HOME"
        "$SERVER_HOME"
        "$RUNTIME_LOGS"
    )

    for p in "${paths[@]}"; do
        [[ -z "$p" || "$p" == "null" ]] && {
            echo "Chemin invalide dans paths.json"
            echo "$(date) [Chemin invalide dans paths.json] ERROR" >> "$RUNTIME_LOGS/logs.txt"
            exit 1
        } || echo "Chemin $p [ validé ]" >/dev/null 2>&1
    done
}

check_permissions() {
    for dir in "$INSTALL_ROOT" "$INSTALL_TMP"; do
        mkdir -p "$dir" 2>/dev/null || {
            echo "Permissions insuffisantes pour $dir"
            echo "$(date) [Need Access for $dir] ERROR" >> "$RUNTIME_LOGS/logs.txt"
            exit 1
        } || echo "Droit Dossier $dir [ validé ]" >/dev/null 2>&1
    done
}

check_disk_space() {
    local required_mb=400
    local avail_mb

    avail_mb=$(df -Pm "$INSTALL_ROOT" | awk 'NR==2 {print $4}')

    [[ "$avail_mb" -lt "$required_mb" ]] && {
        echo "Espace disque insuffisant (${avail_mb}MB disponibles)"
        echo "$(date) [Espace Requis] ERROR" >> "$RUNTIME_LOGS/logs.txt"
        exit 1
    } || echo "Espace requis validé" >/dev/null 2>&1
}

check_runtime_conflicts() {
    if [[ -f "$RUNTIME_STATE" ]]; then
        jq . "$RUNTIME_STATE" >/dev/null || {
            echo "runtime/state.json corrompu"
            echo "$(date) [runtime/state.json] ERROR" >> "$RUNTIME_LOGS/logs.txt"
            exit 1
        }
    else
        echo "Fichier $RUNTIME_STATE invalide"
        echo "$(date) [$RUNTIME_STATE] ERROR" >> "$RUNTIME_LOGS/logs.txt"
        exit 1
    fi
}
