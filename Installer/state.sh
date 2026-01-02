#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# State management — runtime/state.json & runtime/version.json
###############################################################################

###############################################################################
# Initialisation
###############################################################################

state_init() {
    mkdir -p "$(dirname "$RUNTIME_STATE")" "$RUNTIME_LOGS"

    [[ -f "$RUNTIME_STATE" ]] || init_state_file
    [[ -f "$RUNTIME_VERSION" ]] || init_version_file

    validate_state
}

init_state_file() {
    cat > "$RUNTIME_STATE" <<'EOF'
{
  "components": {
    "service": {
      "installed": false,
      "ok": false,
      "last_action": null
    },
    "server": {
      "installed": false,
      "ok": false,
      "last_action": null
    }
  },
  "builder": {
    "last_build": null
  }
}
EOF
}

init_version_file() {
    cat > "$RUNTIME_VERSION" <<'EOF'
{
  "installed": null,
  "build": null,
  "channel": "stable"
}
EOF
}

###############################################################################
# Validation
###############################################################################

validate_state() {
    jq . "$RUNTIME_STATE" >/dev/null 2>&1 || {
        echo "state.json invalide ou corrompu"
        exit 1
    }

    jq . "$RUNTIME_VERSION" >/dev/null 2>&1 || {
        echo "version.json invalide ou corrompu"
        exit 1
    }
}

###############################################################################
# Setters atomiques
###############################################################################

state_set() {
    local path="$1"
    local value="$2"

    tmp="$(mktemp)"
    jq "$path = $value" "$RUNTIME_STATE" > "$tmp"
    mv "$tmp" "$RUNTIME_STATE"
}

version_set() {
    local path="$1"
    local value="$2"

    tmp="$(mktemp)"
    jq "$path = $value" "$RUNTIME_VERSION" > "$tmp"
    mv "$tmp" "$RUNTIME_VERSION"
}

###############################################################################
# Getters
###############################################################################

state_get() {
    local path="$1"
    jq -r "$path" "$RUNTIME_STATE"
}

version_get() {
    local path="$1"
    jq -r "$path" "$RUNTIME_VERSION"
}

###############################################################################
# Helpers haut niveau
###############################################################################

mark_component_installed() {
    local comp="$1"

    state_set ".components.$comp.installed" true
    state_set ".components.$comp.ok" true
    state_set ".components.$comp.last_action" "\"install\""
}

mark_component_removed() {
    local comp="$1"

    state_set ".components.$comp.installed" false
    state_set ".components.$comp.ok" false
    state_set ".components.$comp.last_action" "\"remove\""
}

mark_build() {
    state_set ".builder.last_build" "\"$(date -Is)\""
}

mark_version_installed() {
    local version="$1"
    version_set ".installed" "\"$version\""
    version_set ".build" "\"$(date -Is)\""
}

###############################################################################
# Diagnostics / repair-ready
###############################################################################

state_summary() {
    echo "=== Components ==="
    jq -r '.components | to_entries[] |
        "\(.key): installed=\(.value.installed) ok=\(.value.ok)"' \
        "$RUNTIME_STATE"

    echo
    echo "=== Version ==="
    jq . "$RUNTIME_VERSION"
}

component_status() {
    local component="$1"
    local field="$2"
    jq -r ".components.$component.$field" "$RUNTIME_STATE"
}

component_installed() {
    local component="$1"
    [[ "$(component_status "$component" "installed")" == "true" ]]
}

component_ok() {
    local component="$1"
    [[ "$(component_status "$component" "ok")" == "true" ]]
}

component_last_action() {
    local component="$1"
    jq -r ".components.$component.last_action" "$RUNTIME_STATE"
}

overall_status() {
    if component_installed "service" && component_installed "server" &&
       component_ok "service" && component_ok "server"; then
        return 0
    else
        return 1
    fi
}

repair_state() {
    echo "Réparation de l'état..."
    state_init
    echo "État réparé."
}
