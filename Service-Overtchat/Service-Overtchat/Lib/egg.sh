#!/usr/bin/env bash

                                        # ────────────────────────────── #
                                        #   Création du fichier eggdrop.sh
                                        # ────────────────────────────── #

create_eggdrop_sh() {
# Fichier Eggdrop
if [[ -n "${shell[build_egg]+_}" ]]; then

if [[ ! "$(find "$HOME/${folders[dir_lib]}" -type f -name "$(basename -- "${shell[build_egg]}")" -print -quit 2>/dev/null)" ]]; then
    warn "Création du fichier $(basename -- "${shell[build_egg]}") [ en cours... ]"

    cat >"$HOME/${shell[build_egg]}" <<'EGG'
#!/usr/bin/env bash
set -euo pipefail

mess() { echo -e "\e[32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
die() { echo -e "\e[31m[ERROR]\e[0m $*"; exit 1; }
quest() { echo -e "\e[35m[QUEST]\e[0m $*"; }

# source du bot
egg[files]="/tmp/.egg.tmp"

# Création du fichier config
if [[ ! -f "${egg[files]}" ]]; then
mess "Création du fichier de configuration [ ${egg[files]} ]"
cat > "${egg[files]}" <<'EOF'
# Déclaration variable Eggdrop
declare -A egg dev

# Définition des variables
egg[bot]="$botnick"
egg[eggdrop]="$HOME/${egg[bot]}"
egg[config]="${egg[eggdrop]}/${egg[bot]}.conf"
egg[source]="${egg[eggdrop]}/scripts"
egg[prog]="${egg[source]}/services.tcl"
egg[repo]="https://github.com/eggheads/eggdrop.git"

# Source configuration
egg[source]="${egg[files]}"

# Variable numéric 
dev[vers]=1.0.0.0
dev[auto]=0
dev[pub]=0
dev[maj]=0
dev[alerte]=0
dev[sock]=0
dev[dev]=0
EOF
fi

# Chargement fichier tmp au démarrage
[[ -f "${egg[files]}" ]] && source "${egg[files]}" && mess "Chargement du fichier de configuration [ ${egg[files]} ]"

# On modifie les variables selon choix utilisateur si conf inexistante
if [[ ! -f "${egg[files]}~conf" ]]; then
	mess "Bienvenue sur l'installateur automatisé by Service-Overtchat. \ 
Ce systême a pour but l'auto-install Eggdrop avec son programme autonome."
	
	declare -A options=(
        [auto]="la gestion automatique du programme"
        [maj]="la mise à jour automatique"
        [pub]="la gestion des pubs sur les salons"
        [alerte]="les alertes d'erreurs"
        [sock]="les Sockets (Gestion Ulines requis)"
        [dev]="les fonctionnalités Développeur"
    )

    for key in "${!options[@]}"; do
        while true; do
            quest "Souhaitez-vous activer ${options[$key]} ? (Y/N) : "
            read -r choice
            case "$choice" in
                Y|y|O|o)
                    sed -i "s/dev\[$key\]=0/dev[$key]=1/" "${egg[files]}"
                    break
                    ;;
                N|n|Q|q)
                    # rien à faire, la valeur reste à 0
                    break
                    ;;
                *)
                    mess "Réponse invalide. Merci de répondre par Y ou N."
                    ;;
            esac
        done
    done

    echo "Configuration eggdrop ok" > "${egg[files]}~conf"
fi

# Fonction principale
main() {
    cd "$HOME" || die "Échec de l'accès au répertoire $HOME."

    # Vérification des dépendances
    for cmd in git; do
        if ! command -v "$cmd" &> /dev/null; then
            die "La commande '$cmd' est requise mais n'est pas installée. Veuillez l'installer et réessayer."
        fi
    done

    # Vérification des permissions
    if [[ ! -w "$HOME" ]]; then
        die "Le script n'a pas les permissions d'écriture dans le répertoire $HOME."
    fi

    # Vérification des commandes
    case $1 in
        install|uninstall|update|restart|status|start|stop|clean|help) ;;
        *)
            mess "Commande inconnue : $1"
            mess "Commandes disponibles : install, uninstall, update, restart, status, start, stop, clean, help"
            exit 1
            ;;
    esac
    # Appel de la fonction correspondante
    "$1"
}

# Fonction d'installation
install() {
    # Code d'installation
    mess "Installation de l'eggdrop..."
    if [[ -d "${egg[eggdrop]}:-" ]]; then
        warn "L'eggdrop est déjà installé."
        exit 1
    fi
	
	# On télécharge sur le dépôt eggdrop
    git clone "$repo" . || die "Échec du clonage du dépôt Git."
	
    mess "Installation terminée."
}

# Fonction de désinstallation
uninstall() {
    # Code de désinstallation
    mess "Désinstallation de l'eggdrop..."
    if [[ -d "${egg[eggdrop]}:-" ]]; then
        rm -rf "${egg[eggdrop]}" || die "Échec de la suppression du répertoire ${egg[eggdrop]}."
        mess "Désinstallation terminée."
    else
        warn "L'eggdrop n'est pas installé."
        exit 1
    fi
}

# Fonction de mise à jour
update() {
    # Code de mise à jour
    mess "Mise à jour de l'eggdrop..."
    if [[ -d "${egg[eggdrop]}:-" ]]; then
		cd "${egg[eggdrop]}" || exit 1
		git pull origin main || die "Échec de la mise à jour depuis le dépôt Git."
		mess "Mise à jour terminée."
		restart
	else
		die "${egg[eggdrop]} inexistant"
	fi
}

# Fonction de redémarrage
restart() {
    # Code de redémarrage
    mess "Redémarrage de l'eggdrop..."
    stop
    start
}

# Fonction de statut
status() {
    # Code de statut
    mess "Statut de l'eggdrop..."
    pids=$(pgrep -f "${egg[bot]}")
    if [[ -n "$pids" ]]; then
        warn "L'eggdrop est en cours d'exécution avec le PID(s) : $pids"
    else
        mess "L'eggdrop n'est pas en cours d'exécution."
    fi
}

# Fonction de démarrage
start() {
	# Code de démarrage
	mess "Démarrage de l'eggdrop..."
    if cd "${egg[eggdrop]}"; then
		# Vérification si le bot est déjà en cours d'exécution
		pids=$(pgrep -f "${egg[bot]}")
		if [[ -n "$pids" ]]; then
			warn "L'eggdrop est déjà en cours d'exécution avec le PID(s) : $pids"
			exit 1
		fi
		# Démarrage de l'eggdrop
		local files=${egg[config]}
		if [[ ! -f "$files" ]]; then
			die "Fichier de configuration ${egg[config]} introuvable."
		fi
		if [[ ! -f "${egg[prog]}" ]]; then
			die "Fichier de programme ${egg[prog]} introuvable."
		fi
		# 1er démarrage
        if [[ ! -f "${egg[eggdrop]}/eggdrop.user" ]]; then
            ./eggdrop -m "$files" || die "Échec du premier démarrage de l'eggdrop."
        else
		    # 2ème démarrage et +
		    ./eggdrop "$files" || die "Échec du démarrage de l'eggdrop."
        fi
		mess "Démarrage terminé."
	else
		die "Dossier ${egg[bot]} inexistant"
	fi
}

# Fonction de stop
stop() {
    mess "Arrêt de l'eggdrop..."
    pids=$(pgrep -f "${egg[bot]}")
    if [[ -z "$pids" ]]; then
        warn "Aucun eggdrop au nom de ${egg[bot]} actuellement en cours d'exécution."
        return
    fi
    kill $pids
    mess "Eggdrop arrêté."
}

# Fonction de nettoyage
clean() {
    # Code de nettoyage
    mess "Nettoyage de l'eggdrop..."
    if cd "${egg[eggdrop]}"; then
		find . -type f -name '*.o' -delete
		find . -type f -name '*~' -delete
		mess "Nettoyage terminé."
	else
		err "Dossier ${egg[bot]} inexistant"
	fi
}

help() {
cat <<'EOF'
Aide générale pour ${egg[bot]}. Vous trouverez ci-joint la liste des commandes disponible ou en cours de développement.
Installé Eggdrop : ./egg.sh install
Lancé l'eggdrop : ./egg.sh start
Arrêter l'eggdrop : ./egg.sh stop
Relancé eggdrop : ./egg.sh restart
Mise à jour Eggdrop : ./egg.sh update
Nettoyage des fichiers : ./egg.sh clean
Etat générale de l'eggdrop : ./egg.sh status
EOF
mess "Liste des commandes disponiblent"
help "$@"
}

# Fonction principale
main "$@"

# Fin du programme
EGG
    : $((debug++))
else
    valid "Fichier $(basename -- "${shell[build_egg]}") [ actif ]"
    : $((debug++))
fi
fi
}