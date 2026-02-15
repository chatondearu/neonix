# Gaming setup instructions

# Steam 

to see : https://discourse.nixos.org/t/unable-to-add-new-library-folder-to-steam/38923

## VR

### Monado OpenXR runtime

to launch monado execute :
```shell
systemctl --user start monado.service

journalctl --user --follow --unit monado.service
```

### WayVR

see : https://github.com/wlx-team/wayvr?tab=readme-ov-file

Parfait ! Voici un guide complet pour tester votre configuration NVIDIA gaming/VR après avoir appliqué les modifications recommandées :

## 🧪 Guide de Tests - Configuration NVIDIA Gaming & VR

### 🔍 Étape 1 : Vérification du Driver NVIDIA

**1.1 - Vérifier que le driver propriétaire est chargé**
```bash
cat /proc/driver/nvidia/version
# Devrait afficher la version avec "Proprietary" au lieu de "Open"
```

**1.2 - Tester nvidia-smi (outil de monitoring)**
```bash
nvidia-smi
# Devrait afficher votre RTX 3090 avec utilisation GPU, mémoire, etc.
```

**1.3 - Vérifier les device nodes**
```bash
ls -la /dev/nvidia*
# Tous les devices doivent avoir les permissions 666 (rw-rw-rw-)
```

**1.4 - Vérifier les modules kernel**
```bash
lsmod | grep nvidia
# Devrait lister: nvidia, nvidia_drm, nvidia_modeset, nvidia_uvm
```

### 🎮 Étape 2 : Tests OpenGL et Vulkan

**2.1 - Test OpenGL basique**
```bash
glxinfo | grep "OpenGL renderer"
# Devrait afficher: OpenGL renderer string: NVIDIA GeForce RTX 3090/PCIe/SSE2

glxgears
# Une fenêtre avec des engrenages 3D devrait s'ouvrir
# Vérifiez le FPS dans le terminal (devrait être >1000 FPS)
```

**2.2 - Test Vulkan**
```bash
vulkaninfo --summary
# Devrait lister votre RTX 3090 sans erreurs

vkcube
# Un cube 3D en rotation devrait s'afficher
# Vérifiez qu'il tourne sans saccades
```

**2.3 - Test avec glxinfo détaillé**
```bash
glxinfo | grep -E "direct rendering|OpenGL version|OpenGL vendor"
# direct rendering: Yes (CRITIQUE - doit être "Yes")
# OpenGL version: devrait être 4.6+
# OpenGL vendor: NVIDIA Corporation
```

### 🎯 Étape 3 : Tests Steam et Gaming

**3.1 - Lancer Steam**
```bash
steam
```

Dans Steam, vérifiez :
- **Settings > System** : Vérifiez que Vulkan est disponible
- **Help > System Information** : Cherchez "Video Card" et vérifiez que c'est bien la RTX 3090

**3.2 - Test avec un jeu natif**

Lancez un jeu natif Linux (ex: CS2, Portal 2) :
```bash
# Dans le terminal avant de lancer :
mangohud %command%
# Cela affichera les FPS et l'utilisation GPU en overlay
```

Vérifiez :
- FPS stables et élevés
- Pas de saccades
- GPU utilisé à fond (visible dans MangoHud)

**3.3 - Test avec Proton (jeu Windows)**

Lancez un jeu Windows via Proton et vérifiez :
```bash
# Dans les propriétés du jeu > Launch Options, ajoutez :
PROTON_LOG=1 mangohud %command%

# Regardez les logs après :
cat ~/steam-*.log | grep -i vulkan
# Devrait montrer l'initialisation Vulkan correcte
```

**3.4 - Test Gamescope**
```bash
gamescope -W 1920 -H 1080 -r 144 -- vkcube
# Lance vkcube dans une fenêtre gamescope
# Devrait fonctionner sans erreurs
```

### 🥽 Étape 4 : Tests VR

**4.1 - Test de connexion Quest (filaire via ADB)**
```bash
# Connectez votre Quest en USB
adb devices
# Devrait lister votre Quest avec "device" (pas "unauthorized")

# Si "unauthorized", acceptez sur le casque et réessayez
```

**4.2 - Test WiVRn (VR sans fil)**

```bash
# Vérifier que WiVRn est actif
systemctl --user status wivrn
# Devrait être "active (running)"

# Lancer WiVRn
wivrn-server
# Devrait démarrer sans erreurs
# Sur votre Quest, lancez l'app WiVRn et connectez-vous
```

Vérifications :
- La connexion doit s'établir rapidement
- Pas de lag perceptible
- Les contrôleurs sont bien trackés

**4.3 - Test SteamVR**

```bash
# Lancer SteamVR depuis Steam
# Ou via terminal pour voir les logs :
~/.steam/steam/steamapps/common/SteamVR/bin/vrmonitor.sh
```

Vérifiez :
- SteamVR démarre sans crasher
- L'environnement SteamVR s'affiche dans le casque
- Les contrôleurs sont détectés
- Pas de message d'erreur GPU

**4.4 - Test d'un jeu VR**

Lancez un jeu VR simple (ex: The Lab, Beat Saber) :
- Framerate stable à 90Hz (Quest 2) ou 120Hz (Quest 3)
- Pas de reprojection visible
- Tracking fluide

### 🔧 Étape 5 : Diagnostic en cas de problème

**Si nvidia-smi ne fonctionne pas :**
```bash
dmesg | grep -i nvidia
# Cherchez des erreurs de chargement du driver
```

**Si OpenGL ne fonctionne pas :**
```bash
glxinfo 2>&1 | head -50
# Cherchez les erreurs

echo $LD_LIBRARY_PATH
# Vérifiez que les libs NVIDIA sont dans le PATH
```

**Si Vulkan échoue :**
```bash
vulkaninfo 2>&1 | grep -i error
# Identifiez les erreurs spécifiques

ls -la /run/opengl-driver/lib/libvulkan*
# Vérifiez que les libs Vulkan NVIDIA existent
```

**Si Steam crashe :**
```bash
# Lancez Steam en mode debug
steam -console
# Dans la console Steam, tapez : vulkan_info
```

**Si WiVRn ne se connecte pas :**
```bash
journalctl --user -u wivrn -f
# Suivez les logs en temps réel

# Vérifiez le firewall
sudo iptables -L -n | grep 9757
# Le port 9757 doit être ouvert
```

**Si SteamVR crashe :**
```bash
# Logs SteamVR
cat ~/.steam/steam/logs/vrserver.txt

# Vérifiez les crashs systemd
coredumpctl list | grep vr
# Si des crashs apparaissent, analysez avec :
coredumpctl info <PID>
```

### 📊 Étape 6 : Benchmarks de performance

**6.1 - Benchmark GPU basique**
```bash
glmark2
# Score devrait être >10000 pour une RTX 3090
```

**6.2 - Benchmark Vulkan**
```bash
vkmark
# Si disponible, sinon utilisez un jeu avec benchmark intégré
```

**6.3 - Test shader compilation**
```bash
# Lancez un jeu Proton la première fois
# Surveillez la compilation des shaders
# Les fois suivantes, le démarrage devrait être instantané (cache fonctionnel)
```

### ✅ Checklist Finale

Après tous les tests, vérifiez que :

- [ ] `nvidia-smi` affiche votre RTX 3090
- [ ] `glxinfo` montre "direct rendering: Yes"
- [ ] `vkcube` tourne à >1000 FPS
- [ ] Steam détecte la RTX 3090
- [ ] Un jeu natif Linux fonctionne bien
- [ ] Un jeu Proton fonctionne bien
- [ ] MangoHud affiche les stats GPU
- [ ] Gamescope fonctionne
- [ ] ADB détecte votre Quest
- [ ] WiVRn se connecte au Quest
- [ ] SteamVR démarre sans crasher
- [ ] Un jeu VR est jouable sans lag

### 🎉 Bonus : Optimisations avancées

Si tout fonctionne, vous pouvez peaufiner :

```bash
# Monitorer les performances GPU en temps réel
watch -n 1 nvidia-smi

# Tester différentes versions de Proton
# Dans Steam > Propriétés du jeu > Compatibilité

# Ajuster les settings MangoHud
# Créez ~/.config/MangoHud/MangoHud.conf
```