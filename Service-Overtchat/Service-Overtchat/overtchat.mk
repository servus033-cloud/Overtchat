# ──────────────────────────────────────────────────
# Config Makefile - Service-Overtchat
# ──────────────────────────────────────────────────
# overtchat.mk - Makefile complet pour build + package Service-Overtchat
SHELL := /bin/bash
.PHONY: all clone encrypt patch prepare_pack release clean mrproper

# -------- CONFIG ----------
HOME := $(shell echo $$HOME)
TMP_BUILD := $(PWD)/.build_overtchat
GIT_REPO := https://github.com/servus033-cloud/Overtchat.git
GIT_BRANCH := main

# Nom final
PKG_NAME := Service-Overtchat
VERSION_FILE := $(TMP_BUILD)/VERSION
OUT_DIR := $(PWD)/dist
SHC := shc

# Répertoires relatifs *dans* le repo cloné
REPO_BASE := Service-Overtchat
LIB_SUB := $(REPO_BASE)/Lib
CONF_SUB := $(REPO_BASE)/Conf
UNIX_IRIX_SUB := $(REPO_BASE)/Unix/IriX
SETUP_SCRIPT := $(REPO_BASE)/setup-overtchat.sh

# Dossier pour binaires chiffrés dans le package
PKG_BIN := bin

# -------- CIBLES ----------
all: release

# Clean temp build area
clean:
	@echo "Nettoyage temporaire"
	@rm -rf "$(TMP_BUILD)"
	@rm -rf "$(OUT_DIR)"
	@echo "Nettoyage effectué"

# Supprime tout (incl. dist)
mrproper: clean
	@echo "Nettoyage complet"
	@rm -rf "$(TMP_BUILD)" "$(OUT_DIR)"
	@echo "mrproper OK"

# 1) Clone propre dans TMP_BUILD
clone: clean
	@echo "Clonage du dépôt dans $(TMP_BUILD)"
	@git clone -b $(GIT_BRANCH) $(GIT_REPO) $(TMP_BUILD)
	@echo "Dépôt cloné"

# 2) Récupère version git et prépare structure
prepare_pack: clone
	@echo "Préparation du build"
	@mkdir -p "$(OUT_DIR)"
	@cd "$(TMP_BUILD)" && git rev-parse --short HEAD > "$(VERSION_FILE)" || echo "unknown" > "$(VERSION_FILE)"
	@echo "Version capturée: $$(cat $(VERSION_FILE))"

# 3) Chiffrement via shc (Lib/*.sh, Conf/*.sh si présents, setup-overtchat.sh, IriX/installirix.sh)
encrypt: prepare_pack
	@echo "Démarrage chiffrement (shc) dans $(TMP_BUILD)"
	@mkdir -p "$(TMP_BUILD)/$(PKG_BIN)"
	# Lib/*.sh
	@if ls "$(TMP_BUILD)/$(LIB_SUB)"/*.sh >/dev/null 2>&1; then \
		for f in "$(TMP_BUILD)/$(LIB_SUB)"/*.sh; do \
			name=$$(basename $$f .sh); \
			out="$(TMP_BUILD)/$(PKG_BIN)/Lib_$$name"; \
			echo " shc $$f -> $$out"; \
			$(SHC) -f $$f -o "$$out" || (echo "shc failed for $$f" && exit 1); \
			chmod +x "$$out" || true; \
		done; \
	else \
		echo " Aucun .sh dans $(LIB_SUB)"; \
	fi
	# Conf/*.sh (optionnel)
	@if ls "$(TMP_BUILD)/$(CONF_SUB)"/*.sh >/dev/null 2>&1; then \
		for f in "$(TMP_BUILD)/$(CONF_SUB)"/*.sh; do \
			name=$$(basename $$f .sh); \
			out="$(TMP_BUILD)/$(PKG_BIN)/Conf_$$name"; \
			echo " shc $$f -> $$out"; \
			$(SHC) -f $$f -o "$$out" || (echo "shc failed for $$f" && exit 1); \
			chmod +x "$$out" || true; \
		done; \
	else \
		echo " Aucun .sh dans $(CONF_SUB)"; \
	fi
	# setup-overtchat.sh
	@if [ -f "$(TMP_BUILD)/$(SETUP_SCRIPT)" ]; then \
		out="$(TMP_BUILD)/$(PKG_BIN)/setup-overtchat"; \
		echo " shc $(SETUP_SCRIPT) -> $$out"; \
		$(SHC) -f "$(TMP_BUILD)/$(SETUP_SCRIPT)" -o "$$out" || (echo "shc failed for setup" && exit 1); \
		chmod +x "$$out" || true; \
	else \
		echo " $(SETUP_SCRIPT) introuvable"; \
	fi
	# IriX/installirix.sh
	@if [ -f "$(TMP_BUILD)/$(UNIX_IRIX_SUB)/installirix.sh" ]; then \
		out="$(TMP_BUILD)/$(PKG_BIN)/IriX_installirix"; \
		echo " shc $(UNIX_IRIX_SUB)/installirix.sh -> $$out"; \
		$(SHC) -f "$(TMP_BUILD)/$(UNIX_IRIX_SUB)/installirix.sh" -o "$$out" || (echo "shc failed for irix" && exit 1); \
		chmod +x "$$out" || true; \
	else \
		echo " $(UNIX_IRIX_SUB)/installirix.sh introuvable"; \
	fi
	@echo "Chiffrement terminé"

# 4) Patch automatique (utilise tools/patch_calls.sh fourni dans le repo cloné)
patch: encrypt
	@echo "Patch des chemins pour pointer vers bin/"
	@if [ -x "$(TMP_BUILD)/tools/patch_calls.sh" ]; then \
		bash "$(TMP_BUILD)/tools/patch_calls.sh" "$(TMP_BUILD)" "$(PKG_BIN)"; \
	else \
		echo "   - tools/patch_calls.sh non présent ou non exécutable dans le repo cloné. Pas de patch automatique."; \
	fi
	@echo "Patch effectué (quand possible)"

# 5) Prépare l'arbo pour l'archive: copie fichiers sources essentiels + bin/
pack_prepare: patch
	@echo "Préparation de l'archive dans $(OUT_DIR)"
	@rm -rf "$(OUT_DIR)/$(PKG_NAME)" && mkdir -p "$(OUT_DIR)/$(PKG_NAME)"
	# Copie des dossiers importants (source non chiffrée facultative)
	@cp -a "$(TMP_BUILD)/$(REPO_BASE)/Conf" "$(OUT_DIR)/$(PKG_NAME)/" 2>/dev/null || true
	@cp -a "$(TMP_BUILD)/$(REPO_BASE)/Unix" "$(OUT_DIR)/$(PKG_NAME)/" 2>/dev/null || true
	# Copie du dossier bin (chiffrés)
	@mkdir -p "$(OUT_DIR)/$(PKG_NAME)/$(PKG_BIN)"
	@cp -a "$(TMP_BUILD)/$(PKG_BIN)"/* "$(OUT_DIR)/$(PKG_NAME)/$(PKG_BIN)/" 2>/dev/null || true
	# Ajoute VERSION
	@cp "$(VERSION_FILE)" "$(OUT_DIR)/$(PKG_NAME)/VERSION" 2>/dev/null || true
	# Ajoute README minimal
	@printf "Service-Overtchat\nVersion: $$(cat $(VERSION_FILE) 2>/dev/null || echo unknown)\n" > "$(OUT_DIR)/$(PKG_NAME)/README.txt"
	@echo "Préparation de l'arbo OK"

# 6) Génère l'archive finale tar.gz
release: pack_prepare
	@echo "Compression finale (tar.gz)"
	@mkdir -p "$(OUT_DIR)"
	@ver="$$(cat $(VERSION_FILE) 2>/dev/null || echo unknown)"; \
	tgt="$(OUT_DIR)/$(PKG_NAME)-v$$ver.tar.gz"; \
	cd "$(OUT_DIR)" && tar -czf "$$tgt" "$(PKG_NAME)"; \
	echo "Archive créée: $$tgt"
