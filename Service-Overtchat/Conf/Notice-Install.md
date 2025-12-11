# Service-Overtchat - Guide d'installation

Bienvenue dans Service-Overtchat !  
Ce guide vous expliquera pas à pas comment installer et configurer le programme sur votre machine.

---

## 1. Prérequis

- Système Unix/Linux ou Windows (selon le build choisi)
- Bash ou terminal compatible
- Droits suffisants pour exécuter des scripts
- Accès à Internet pour récupérer les fichiers si nécessaire

---

## 2. Décompression du package

1. Téléchargez le fichier `Service-Overtchat.tar.gz`
2. Placez-le dans le dossier de votre choix
3. Décompressez-le avec la commande : tar -xzf Service-Overtchat.tar.gz

---

## 3. Configuration

1. Accédez au dossier `Service-Overtchat/Conf`
2. Éditez le fichier `overtchat.conf` si nécessaire pour adapter les paramètres à votre environnement
3. Lisez ce fichier attentivement pour comprendre les options disponibles

---

## 4. Installation

1. Lancez le script d’installation principal situé dans `Install/setup.sh` : cd Install && ./setup.sh

2. Le script va :  

- Compiler le projet si nécessaire  
- Copier les fichiers dans `Service-Overtchat`  
- Préparer les builds Unix/Windows selon votre OS

---

## 5. Vérification

- Vérifiez que tous les dossiers ont été créés : `Build/`, `Lib/`, `Logs/`, `Eggdrop/`  
- Vérifiez que les fichiers dans `Conf/` et `Lib/` sont bien présents

---

## 6. Lancement

- Pour lancer Service-Overtchat : utilisez le script prévu dans `Lib/setup-overtchat.sh` ou suivez les instructions internes à votre build

---

## 7. Mise à jour / patch

- Les mises à jour se font via `Install/bin/patch_overtchat.sh`  
- Suivez les instructions fournies dans le script pour appliquer les modifications

---

## 8. Support

- Pour toute question, vérifiez les logs dans `Logs/`  
- Contactez le développeur si vous rencontrez des problèmes persistants

---

Merci d’utiliser Service-Overtchat !
