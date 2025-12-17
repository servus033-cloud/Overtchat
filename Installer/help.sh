#!/usr/bin/env bash

# -----------------------------
# Affichage principal
# -----------------------------
show_panel() {
    local mode="${1:-}"

    cat <<EOF
${BLUE}────────────────────────────────────────────${NC}
${BLUE}   Panel Information — Service-Overtchat    ${NC}
${BLUE}────────────────────────────────────────────${NC}

EOF

    if [[ "$mode" == "help" ]]; then
        show_help
    else
        show_commands
    fi
}

# -----------------------------
# Commandes disponibles (court)
# -----------------------------
show_commands() {
    cat <<EOF
${YELLOW}Commandes disponibles :${NC}

  ${GREEN}install${NC}    Installer Service-Overtchat / Serveur
  ${MAUVE}config${NC}     Générer le fichier de configuration
  ${PINK}update${NC}     Vérifier / appliquer les mises à jour
  ${RED}delete${NC}     Désinstaller Service / Serveur
  ${YELLOW}init${NC}       Réinitialiser le dépôt Git
  ${GREEN}statut${NC}     Afficher l'état du programme
  ${BLUE}help${NC}       Afficher l'aide détaillée

${YELLOW}Syntaxe :${NC}
  ${GREEN}${0}${NC} <commande> [options]

Tapez ${BLUE}--help${NC} pour plus de détails.
EOF
}

# -----------------------------
# Aide détaillée
# -----------------------------
show_help() {
    cat <<EOF
${YELLOW}Aide détaillée — Commandes :${NC}

${GREEN}--install <service | server | all>${NC}
  Installe Service-Overtchat, le Serveur ou les deux.

${MAUVE}--config${NC}
  Lance la configuration interactive et génère les fichiers nécessaires.

${PINK}--update [-y | --dry-run]${NC}
  Vérifie et applique les mises à jour depuis le dépôt Git.
  -y         : mise à jour automatique sans confirmation
  --dry-run  : simulation sans modification

${RED}--delete <service | server | all>${NC}
  Désinstalle le ou les composants sélectionnés.

${YELLOW}--init${NC}
  Réinitialise le dépôt Git local en cas de problème.

${GREEN}--statut [--json]${NC}
  Affiche l'état du programme et des composants.

${BLUE}--help${NC}
  Affiche cette aide détaillée.

${YELLOW}Exemples :${NC}
  ${GREEN}${0}${NC} --config
  ${GREEN}${0}${NC} --install service
  ${GREEN}${0}${NC} --update -y
  ${GREEN}${0}${NC} --delete all
EOF
}

show_help_install() {
cat <<EOF
${GREEN}--install <service | server | all>${NC}

Installe les composants du programme.

  service   Installe Service-Overtchat
  server    Installe Serveur-Overtchat
  all       Installe Service + Serveur

Exemples :
  ${0} --install service
  ${0} --install all
EOF
}

show_help_update() {
cat <<EOF
${PINK}--update [-y | --dry-run]${NC}

Met à jour le programme depuis le dépôt Git.

Options :
  -y           Mise à jour automatique (sans confirmation)
  --dry-run    Simulation de la mise à jour

Exemples :
  ${0} --update
  ${0} --update -y
  ${0} --update --dry-run
EOF
}

show_help_delete() {
cat <<EOF
${RED}--delete <service | server | all>${NC}

Désinstalle les composants du programme.

  service   Supprime uniquement Service-Overtchat
  server    Supprime uniquement Serveur-Overtchat
  all       Supprime Service + Serveur + dépôt Git

Exemples :
  ${0} --delete service
  ${0} --delete all
EOF
}

show_help_config() {
cat <<EOF
${MAUVE}--config${NC}

Lance la configuration interactive.
Génère :
  - config.json (source de vérité)
  - overtchat.conf (compatibilité Bash)

Exemple :
  ${0} --config
EOF
}

show_help_statut() {
cat <<EOF
${GREEN}--statut [--json]${NC}

Affiche l'état du programme.

Options :
  --json   Sortie machine-lisible (JSON)

Exemples :
  ${0} --statut
  ${0} --statut --json
EOF
}

show_help_init() {
cat <<EOF
${YELLOW}--init${NC}
Réinitialise le dépôt Git local.
Utile en cas de problème avec les fichiers Git.
Exemple :
  ${0} --init
EOF
}

# -----------------------------
# Fin du script help.sh
# -----------------------------