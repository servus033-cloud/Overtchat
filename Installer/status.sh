#!/usr/bin/env bash
jq -r '.components | to_entries[] | "\(.key): installed=\(.value.installed) ok=\(.value.ok)"' \
    "$RUNTIME_STATE"