#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Parsing CLI
###############################################################################

parse_args() {
    if [[ "$#" -gt 0 ]]; then
        parse_cli "$@"
    else
        interactive_menu
    fi
}

parse_cli() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            install|update|delete|status)
                ACTION="$1"
                ;;
            service|server|all)
                TARGET="$1"
                ;;
            -h|help)
                show_help
                exit 0
                ;;
            *)
                echo "Argument inconnu : $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    validate_selection
}

###############################################################################
# Menu interactif
###############################################################################

interactive_menu() {
    echo
    echo "=== Overtchat Installer ==="
    echo
    echo "Action :"
    select ACTION in install update delete status quit help; do
        [[ "$ACTION" == "quit" ]] && exit 0
        [[ -n "$ACTION" ]] && break
    done

    if [[ "$ACTION" != "status" ]]; then
        echo
        echo "Cible :"
        select TARGET in service server all back; do
            [[ -n "$TARGET" ]] && break
        done
    else
        TARGET="all"
    fi

    validate_selection
}

###############################################################################
# Validation
###############################################################################

validate_selection() {
    [[ -z "$ACTION" ]] && {
        echo "Action manquante"
        exit 1
    }

    if [[ "$ACTION" != "status" && -z "$TARGET" ]]; then
        echo "Cible manquante"
        exit 1
    fi
}

###############################################################################
# Aide
###############################################################################

show_help() {
    cat <<EOF
Usage:
  install.sh install  [service|server|all]
  install.sh update   [service|server|all]
  install.sh delete   [service|server|all]
  install.sh status

Exemples:
  install.sh install service
  install.sh update all
  install.sh status
EOF
}
