# Overtchat

Service-Overtchat est un programme automatisé destiné à simplifier la gestion de communications, avec une structure client/serveur modulable.  
Ce dépôt contient l’ensemble des composants nécessaires à l’installation, au build et au déploiement du programme.

---

## Arborescence du projet

Overtchat/
│
├── Install/
│ ├── MAKEFILE
│ ├── setup.sh
│ └── bin/
│ ├── install-overtchat.sh
│ └── patch_overtchat.sh
│
├── Service-Overtchat/
│ ├── Build/
│ │ ├── UniX/IriX
│ │ └── Windows/
│ ├── Conf/
│ │ ├── overtchat.conf
│ │ └── Notice-install
│ ├── Eggdrop/
│ ├── Lib/
│ │ ├── colors.sh
│ │ ├── core.sh
│ │ ├── data_cover.sh
│ │ ├── egg.sh
│ │ ├── include.sh
│ │ ├── installirix.sh
│ │ ├── mkpassword.sh
│ │ ├── package.sh
│ │ ├── sendmails.sh
│ │ ├── setup-overtchat.sh
│ │ ├── sql.sh
│ │ └── Unix.sh
│ └── Logs/
│
└── Serveur-Overtchat/
└── Programs.fs

---

## Installation

1. Décompressez le fichier `Service-Overtchat.tar.gz`  
2. Configurez `Service-Overtchat/Conf/overtchat.conf` selon votre environnement  
3. Lancez `Install/setup.sh` pour compiler et installer le programme  
4. Suivez les instructions dans `Conf/Notice-install` pour finaliser l’installation

---

## Utilisation

- Pour exécuter le programme, utilisez les scripts situés dans `Lib/` selon votre système  
- Les logs sont disponibles dans `Service-Overtchat/Logs/`  
- Les configurations supplémentaires sont stockées dans `Conf/`

---

## Mise à jour

- Les mises à jour se font via `Install/bin/patch_overtchat.sh`  
- Suivez les instructions du script pour appliquer les patchs

---

## Contribution

- Structurez vos modifications dans `Lib/` ou `Build/`  
- Documentez chaque nouveau module ou script dans le README et, si nécessaire, dans `Notice-install`  
- Respectez les conventions Bash existantes pour garantir la compatibilité

---

## License

À définir selon les règles du projet.
