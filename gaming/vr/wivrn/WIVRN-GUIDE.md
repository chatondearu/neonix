# Guide WiVRn pour Meta Quest 1 sur NixOS

## ✅ Configuration Complète

Votre système NixOS est maintenant correctement configuré pour utiliser WiVRn avec votre Meta Quest 1.

### Modifications Appliquées

#### 1. `/home/chaton/etc/nixos/users.nix`
- Ajout du groupe `adbusers` pour l'utilisateur `chaton`
- Permet l'accès aux appareils Android via ADB

#### 2. `/home/chaton/etc/nixos/gaming/default.nix` (current layout)
- Activation de `programs.adb.enable = true`
- Mise à jour des règles udev pour les casques Meta Quest
- Documentation des Product IDs (Quest 1: 0183/0186, Quest 2: 01a0/01a1, Quest 3: 0360/0361)

Note: in the current repository layout, gaming configuration is split under `/home/chaton/etc/nixos/gaming/` (for example `default.nix` and `vr/vr.nix`) instead of a single `gaming.nix` file.

## 📱 Installation de WiVRn sur le Quest

### Script d'Installation
Un script d'installation est disponible : `/home/chaton/etc/nixos/manual-wivrn-install.sh`

Ce script :
1. Vérifie la connexion ADB
2. Transfère l'APK vers le Quest (~1 seconde)
3. Installe l'application (~8 secondes)
4. Vérifie l'installation

**Utilisation :**
```bash
/home/chaton/etc/nixos/manual-wivrn-install.sh
```

### Prérequis pour l'Installation
- Quest connecté via USB-C
- Quest déverrouillé (pas en veille)
- USB Debugging autorisé sur le Quest

## 🎮 Utilisation de WiVRn

### Session graphique

Cette configuration utilise `niri` (Wayland). Garder les tests WiVRn/SteamVR dans une session utilisateur active, avec les services utilisateur (`systemctl --user`) pour éviter les faux diagnostics.

### Sur le Quest
1. Mettez le casque
2. Ouvrez la bibliothèque d'applications (icône grille)
3. Cliquez sur "All" en haut à droite
4. Trouvez "WiVRn" (probablement dans "Unknown Sources")
5. Lancez WiVRn

### Sur le PC
1. Lancez le tableau de bord : `wivrn-dashboard` ou via le menu des applications
2. Le serveur WiVRn démarrera automatiquement
3. Le Quest détectera automatiquement votre PC sur le même réseau WiFi

### Configuration Réseau
⚠️ **Important** : Le PC et le Quest doivent être sur le **même réseau WiFi** pour que WiVRn fonctionne en mode sans fil.

## 🔧 Dépannage

### Le Quest n'est pas détecté par ADB
```bash
# Vérifier la connexion
adb devices

# Si "offline" ou absent :
adb kill-server
adb start-server
# Débrancher/rebrancher le Quest
# Accepter à nouveau l'autorisation USB debugging sur le Quest
```

### Réinstaller ou Mettre à Jour WiVRn
1. Téléchargez le nouvel APK dans `~/.cache/wivrn/wivrn-dashboard/`
2. Lancez le script d'installation : `/home/chaton/etc/nixos/manual-wivrn-install.sh`

### Le Quest passe en "offline" pendant l'utilisation
- Le casque est entré en veille
- Déverrouillez le Quest (mettez-le sur votre tête)
- La connexion devrait se rétablir automatiquement

## 📝 Notes Techniques

### Pourquoi l'installation en 2 étapes ?
Le Quest 1 est plus lent que les Quest 2/3, et les outils (wivrn-dashboard, adb install) ont des timeouts trop courts. La méthode en 2 étapes :
1. `adb push` - Transfert rapide du fichier
2. `adb shell pm install` - Installation locale (plus rapide, pas de timeout)

### Chemins importants
- APK WiVRn : `~/.cache/wivrn/wivrn-dashboard/wivrn-v25.12.apk`
- Logs WiVRn : `~/.local/state/wivrn/wivrn-dashboard/server_logs_*.txt`
- Configuration ADB : `~/.android/`

## 🎯 Performance

### Résultats de Transfert
- Vitesse USB : ~55-74 MB/s
- Temps de transfert (25 MB) : < 1 seconde
- Temps d'installation : ~8 secondes
- **Total : ~10 secondes** ⚡

## 🔄 Mises à Jour Futures

Après une mise à jour NixOS (`sudo nixos-rebuild switch`), toutes ces configurations sont préservées automatiquement grâce à la configuration déclarative de NixOS.

---

**Note :** Ce guide a été créé le 11 février 2026 pour votre configuration NixOS avec Meta Quest 1.

