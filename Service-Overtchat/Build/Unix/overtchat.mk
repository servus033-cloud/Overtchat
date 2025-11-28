# ──────────────────────────────────────────────────
# Config Makefile - Service-Overtchat
# ──────────────────────────────────────────────────

.DEFAULT_GOAL := help

# Source Principale
HOME := $(shell echo $$HOME)

# Depot Git
GIT_REPO := https://github.com/servus033-cloud/Overtchat.git
GIT_RACINE := Overtchat
GIT_BRANCH := main

# Répertoires d'installation
INSTALL_DIR := $(HOME)/Overtchat

# Fichier Database
CONFIG_FILE := $(INSTALL_DIR)/Conf/overtchat.conf

# URL de base
WEB_BASE := http://service.overtchat.free.fr/

# Debug Return
DEBUG := 0

# SHC
SHC_SRC := $(INSTALL_SCRIPT)
SHC_OUT := $(BIN_DIR)/install_overtchat_shc.c
PROGRAM_BIN := $(BIN_DIR)/install_overtchat

# Définition du compilateur et des options
CC=gcc
CFLAGS=-Wall -Wextra -O2

# Fichiers sources et exécutable
SRC=main.c utils.c
OBJ=$(SRC:.c=.o)
EXEC=$(INSTALL_SCRIPT)

# Règle principale
all: $(EXEC)

# Compilation des fichiers objets
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Édition de liens
$(EXEC): $(OBJ)
$(CC) $(OBJ) -o $(EXEC)
chmod +x $(EXEC)

# Règle d'installation
install: all
	@echo "Installation de Service-Overtchat dans $(INSTALL_DIR)..."
	git clone -b $(GIT_BRANCH) $(GIT_REPO) $(GET_RACINE)
	chmod +x $(GET_RACINE)/Service-Overtchat/Lib/*.sh
	@echo "Installation terminée."
# Règle de nettoyage
clean:
	rm -f $(OBJ) $(EXEC) $(SHC_OUT) $(PROGRAM_BIN)

update:
	@echo "Mise à jour de Service-Overtchat depuis le dépôt Git..."
	cd $(INSTALL_DIR) 
	git pull origin $(GIT_BRANCH)
	git fetch --tags origin
	@echo "Mise à jour terminée."

# Règle d'aide
help:
	@echo "Makefile pour Service-Overtchat"
	@echo ""	@echo "Usage:"
	@echo "  make          - Compilation de l'application"
	@echo "  make install  - Installation de l'application"
	@echo "  make clean    - Nettoie les fichiers compilés"
	@echo "  make help     - Liste des commandes disponibles"
	@echo "  make update   - Met à jour l'application depuis le dépôt Git"

.PHONY: all install clean update help
	@echo ""# Fin du Makefile
