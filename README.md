# REAL LIFE 3D — serveur de salons (prototype)

Ce dossier ajoute un serveur Node.js WebSocket indépendant du projet Godot existant.
Il permet de créer un salon avec code de 6 caractères, rejoindre une partie déjà commencée et transmettre des positions à 20 joueurs par salon.

## Installation GitHub
Copier `package.json` et le dossier `server` à la racine du dépôt.

## Render
Créer un **Web Service** avec Language **Node**, Build Command `npm install`, Start Command `npm start`, Root Directory vide. Render fournit automatiquement `PORT`.

## Protocole WebSocket
Connecter le client à `wss://VOTRE-SERVICE.onrender.com`.
Envoyer `{"type":"create"}` ou `{"type":"join","code":"ABC123"}`.
Réponse `joined` avec `code`, `id`, `players`.
Envoyer `{"type":"move","x":0,"y":2,"z":0,"yaw":0}`.
Recevoir `entered`, `moved`, `left`, `error`.

## Limites importantes
Le jeu Godot actuel utilise ENet/UDP : **il ne se connectera pas à ce serveur sans modifier `main.gd` pour utiliser WebSocketPeer et ce protocole JSON**. Le serveur n'héberge pas la scène 3D et ne rend pas le jeu jouable dans un navigateur. Les salons et positions sont en mémoire, disparaissent lors du redémarrage, sans comptes, anti-triche ni persistance. Le propriétaire du salon n'est pas privilégié. Les performances pour 20 joueurs n'ont pas été testées.
