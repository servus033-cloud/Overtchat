# overtchat.mk - Makefile FULL-AUTO pour Service-Overtchat
SHELL := /bin/bash
.PHONY: all clone prepare encrypt patch pack release clean mrproper strip_sources

# --- CONFIG (modifiable si besoin) ---
GIT_REPO   := https://github.com/servus033-cloud/Overtchat.git
GIT_BRANCH := main

TMP_BUILD  := $(PWD)/.build_overtchat
OUT_DIR    := $(PWD)/dist
PKG_NAME   := Service-Overtchat
SHC        := shc
CC         := gcc

# Structure attendue DANS le repo cloné (exactement)
REPO_BASE     := Service-Overtchat
LIB_SUB       := $(REPO_BASE)/Lib
CONF_SUB      := $(REPO_BASE)/Conf
BUILD_UNIX_IR := $(REPO_BASE)/Build/Unix/IriX
SETUP_SRC     := $(REPO_BASE)/setup-overtchat.sh  # existe; ne sera pas appelé par d'autres scripts

# Emplacement des binaires dans le package (sous Service-Overtchat/bin/)
PKG_BIN := bin

# --- CIBLES par défaut ---
all: release

clean:
	@echo "🧹 Nettoyage temporaire"
	@rm -rf "$(TMP_BUILD)" "$(OUT_DIR)"
	@echo "✔ Nettoyage effectué"

mrproper: clean
	@echo "🧹 Nettoyage complet"
	@rm -rf "$(TMP_BUILD)" "$(OUT_DIR)"
	@echo "✔ mrproper OK"

# 1) clone propre
clone: clean
	@echo "📥 Clonage de $(GIT_REPO) dans $(TMP_BUILD)"
	@git clone -b $(GIT_BRANCH) $(GIT_REPO) "$(TMP_BUILD)" || (echo "Erreur: git clone a échoué" && exit 1)
	@echo "✔ Dépôt cloné"

# 2) préparation : vérifs + création dossiers bin
prepare: clone
	@command -v $(SHC) >/dev/null 2>&1 || (echo "Erreur: '$(SHC)' introuvable. Installe shc (apt install shc)"; exit 1)
	@mkdir -p "$(TMP_BUILD)/$(PKG_BIN)/Lib"
	@mkdir -p "$(TMP_BUILD)/$(PKG_BIN)/IriX"
	@mkdir -p "$(TMP_BUILD)/$(PKG_BIN)/Conf"
	@echo "✔ Préparation OK (bin dirs créés)"

# Helper : ajoute temporairement shebang si absent (usé avant shc)
define ensure_shebang_cmd
first=$$(head -n1 "$(1)" 2>/dev/null || echo ""); \
case "$$first" in \
  \#\!/*) : ;; \
  *) (printf '%s\n' "#!/usr/bin/env bash" "" > "$(1).tmp.$$"; cat "$(1)" >> "$(1).tmp.$$"; mv "$(1).tmp.$$" "$(1)";) ;; \
esac
endef

# 3) encrypt : shc pour Lib/*.sh, Conf/*.sh (si présents), Build/Unix/IriX/installirix.sh, setup-overtchat.sh
encrypt: prepare
	@echo "🔐 Démarrage chiffrement (shc)"
	# Lib/*.sh
	@if ls "$(TMP_BUILD)/$(LIB_SUB)"/*.sh >/dev/null 2>&1; then \
	  for f in "$(TMP_BUILD)/$(LIB_SUB)"/*.sh; do \
	    name=$$(basename $$f .sh); \
	    out="$(TMP_BUILD)/$(PKG_BIN)/Lib/Lib_$$name"; \
	    echo " -> $$f -> $$out"; \
	    cp "$$f" "$$f.bak.$$"; \
	    $(call ensure_shebang_cmd,$$f); \
	    $(SHC) -f "$$f" -o "$$out" >/dev/null 2>&1 || { echo "shc failed for $$f"; mv "$$f.bak.$$" "$$f"; exit 1; }; \
	    chmod +x "$$out" || true; \
	    mv "$$f.bak.$$" "$$f" >/dev/null 2>&1 || true; \
	  done; \
	else \
	  echo " - Aucun .sh dans $(LIB_SUB)"; \
	fi
	# Conf/*.sh (optionnel)
	@if ls "$(TMP_BUILD)/$(CONF_SUB)"/*.sh >/dev/null 2>&1; then \
	  for f in "$(TMP_BUILD)/$(CONF_SUB)"/*.sh; do \
	    name=$$(basename $$f .sh); \
	    out="$(TMP_BUILD)/$(PKG_BIN)/Conf/Conf_$$name"; \
	    echo " -> $$f -> $$out"; \
	    cp "$$f" "$$f.bak.$$"; \
	    $(call ensure_shebang_cmd,$$f); \
	    $(SHC) -f "$$f" -o "$$out" >/dev/null 2>&1 || { echo "shc failed for $$f"; mv "$$f.bak.$$" "$$f"; exit 1; }; \
	    chmod +x "$$out" || true; \
	    mv "$$f.bak.$$" "$$f" >/dev/null 2>&1 || true; \
	  done; \
	else \
	  echo " - Aucun .sh dans $(CONF_SUB)"; \
	fi
	# Build/Unix/IriX/installirix.sh
	@if [ -f "$(TMP_BUILD)/$(BUILD_UNIX_IR)/installirix.sh" ]; then \
	  f="$(TMP_BUILD)/$(BUILD_UNIX_IR)/installirix.sh"; \
	  out="$(TMP_BUILD)/$(PKG_BIN)/IriX_installirix"; \
	  echo " -> $$f -> $$out"; \
	  cp "$$f" "$$f.bak.$$"; \
	  $(call ensure_shebang_cmd,$$f); \
	  $(SHC) -f "$$f" -o "$$out" >/dev/null 2>&1 || { echo "shc failed for irix"; mv "$$f.bak.$$" "$$f"; exit 1; }; \
	  chmod +x "$$out" || true; \
	  mv "$$f.bak.$$" "$$f" >/dev/null 2>&1 || true; \
	else \
	  echo " - $(BUILD_UNIX_IR)/installirix.sh introuvable"; \
	fi
	# setup-overtchat.sh (si existant)
	@if [ -f "$(TMP_BUILD)/$(SETUP_SRC)" ]; then \
	  f="$(TMP_BUILD)/$(SETUP_SRC)"; out="$(TMP_BUILD)/$(PKG_BIN)/setup-overtchat"; \
	  echo " -> $$f -> $$out"; \
	  cp "$$f" "$$f.bak.$$"; \
	  $(call ensure_shebang_cmd,$$f); \
	  $(SHC) -f "$$f" -o "$$out" >/dev/null 2>&1 || { echo "shc failed for setup"; mv "$$f.bak.$$" "$$f"; exit 1; }; \
	  chmod +x "$$out" || true; \
	  mv "$$f.bak.$$" "$$f" >/dev/null 2>&1 || true; \
	else \
	  echo " - $(SETUP_SRC) introuvable"; \
	fi
	@echo "✔ Chiffrement terminé"

# 4) patch: remplace appels littéraux vers Service-Overtchat/... par bin/...
#    utilise tools/patch_calls.sh si présent dans le repo cloné, sinon tools_local/patch_calls.sh fourni localement
patch: encrypt
	@echo "🔧 Patch des chemins pour pointer vers $(PKG_BIN)/"
	@if [ -x "$(TMP_BUILD)/tools/patch_calls.sh" ]; then \
	  bash "$(TMP_BUILD)/tools/patch_calls.sh" "$(TMP_BUILD)" "$(PKG_BIN)"; \
	else \
	  echo " - tools/patch_calls.sh absent dans le repo cloné ; utilisation de tools_local/patch_calls.sh"; \
	  bash "./tools_local/patch_calls.sh" "$(TMP_BUILD)" "$(PKG_BIN)"; \
	fi
	@echo "✔ Patch OK"

# Optional: remove source .sh from the package (uncomment use if desired)
strip_sources:
	@echo "🗑 Suppression des sources .sh du build (ne laisse que bin/...)"; \
	find "$(TMP_BUILD)/$(REPO_BASE)" -type f -name "*.sh" -not -path "$(TMP_BUILD)/$(PKG_BIN)/*" -print0 | xargs -0 -r rm -f || true; \
	echo "✔ Sources supprimées"

# 5) Prépare l'arbo pour l'archive : copy Conf/ Unix/ bin/ VERSION etc.
pack: patch
	@echo "📦 Préparation de l'arbo pour l'archive $(OUT_DIR)"
	@rm -rf "$(OUT_DIR)/$(PKG_NAME)" || true
	@mkdir -p "$(OUT_DIR)/$(PKG_NAME)"
	# copier Conf (fichiers .conf), Unix (sauf scripts binaires), Logs optionnel
	@cp -a "$(TMP_BUILD)/$(REPO_BASE)/Conf" "$(OUT_DIR)/$(PKG_NAME)/" 2>/dev/null || true
	@cp -a "$(TMP_BUILD)/$(REPO_BASE)/Build" "$(OUT_DIR)/$(PKG_NAME)/" 2>/dev/null || true
	@cp -a "$(TMP_BUILD)/$(REPO_BASE)/Logs" "$(OUT_DIR)/$(PKG_NAME)/" 2>/dev/null || true
	# bin
	@mkdir -p "$(OUT_DIR)/$(PKG_NAME)/bin"
	@cp -a "$(TMP_BUILD)/$(PKG_BIN)"/* "$(OUT_DIR)/$(PKG_NAME)/bin/" 2>/dev/null || true
	# VERSION
	@cd "$(TMP_BUILD)" && (git rev-parse --short HEAD > "$(OUT_DIR)/$(PKG_NAME)/VERSION" 2>/dev/null || echo "unknown" > "$(OUT_DIR)/$(PKG_NAME)/VERSION")
	@echo "✔ Arbo OK"

# 6) release : tar.gz final
release: pack
	@echo "📦 Compression finale (tar.gz)"
	@mkdir -p "$(OUT_DIR)"
	@ver="$$(cat "$(OUT_DIR)/$(PKG_NAME)/VERSION" 2>/dev/null || echo unknown)"; \
	tgt="$(OUT_DIR)/$(PKG_NAME)-v$$ver.tar.gz"; \
	cd "$(OUT_DIR)" && tar -czf "$$tgt" "$(PKG_NAME)"; \
	echo "✔ Archive créée: $$tgt"
