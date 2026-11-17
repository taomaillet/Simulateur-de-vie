# REAL LIFE 3D

Prototype de simulation de vie 3D multijoueur créé avec **Godot 4**.

## Installation
1. Installer [Godot 4](https://godotengine.org/download/).
2. Importer `project.godot` dans Godot.
3. Lancer avec **F5**.

## Multijoueur
- Héberger : jusqu’à **20 joueurs**, connexion possible pendant une partie.
- Rejoindre : saisir **l’adresse IP** de l’hôte.
- Port : **UDP 24567**. Sur Internet, une configuration réseau ou un VPN privé peut être nécessaire.
- **Important :** les codes de salon courts et la connexion automatique par code ne sont **pas encore développés**. GitHub Pages ne peut pas héberger directement un serveur Godot ENet.

## Commandes
ZQSD/WASD : bouger · Souris : caméra · Espace : sauter · Échap : menu.

## État du projet
Prototype avec formes 3D simples, sans sauvegarde ni comptes. Non testé automatiquement dans Godot.

## Structure
- `project.godot` : configuration du projet
- `Main.tscn` : scène principale
- `main.gd` : monde, interface et réseau
- `player.gd` : personnage et déplacements
