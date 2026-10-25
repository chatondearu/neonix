# NAS Synology (`hosts/nas`)

Configuration **déclarative** pour le NAS : stacks Docker versionnées ici, déployées sur DSM via SSH. Ce n’est **pas** NixOS sur le NAS — DSM reste l’OS ; ce flake vit sur **neo-nix** (ou toute machine avec Nix + accès SSH).

Voir aussi : [[../../foam/decisions/ADR-002-synology-declarative-docker|ADR-002]].

## Arborescence

```
hosts/nas/
  flake.nix           # apps deploy / bootstrap
  .env                # cible SSH (gitignored)
  stacks/<nom>/       # un dossier = une stack docker compose
  scripts/            # deploy + bootstrap DSM
```

## Prérequis DSM

1. **SSH** : Panneau de configuration → Terminal et SNMP → activer SSH.
2. **Utilisateur `deploy`** (recommandé) : groupe *Administrators* ou droits Docker + écriture sur `NAS_REMOTE_STACKS_DIR`. Clé publique dans le profil DSM.
3. **Docker** : moteur **Container Manager** (voir bootstrap ci-dessous). Les services applicatifs passent par **ce repo**, pas par le Package Center Synology.

## Bootstrap (conteneurs + base sécu, sans apps du store)

### Container Manager sans cliquer dans le store (si possible)

Sur le NAS, en **root** (session admin + `sudo -i` ou SSH admin) :

```bash
# Depuis neo-nix, après avoir copié .env (NAS_USER=admin pour cette étape) :
cd hosts/nas
nix run .#bootstrap
```

Si `synopkg install` échoue (compte Synology, modèle, offline) :

1. Télécharger le `.spk` **Container Manager** pour ton modèle sur le site Synology.
2. Sur le NAS : `synopkg install /chemin/vers/ContainerManager-….spk`
3. Démarrer le paquet dans DSM ou `synopkg start ContainerManager`

Alternative locale :

```bash
ssh admin@NAS 'sudo bash -s' < scripts/bootstrap-on-nas.sh
```

### Sécurisation sans apps tierces du store

| Mesure | Où |
|--------|-----|
| Compte dédié SSH, clés uniquement | Utilisateur DSM + `~/.ssh/authorized_keys` |
| Désactiver / renommer `admin` | Panneau utilisateurs |
| Pare-feu + **Auto block** | Sécurité → Pare-feu / Protection |
| 2FA sur les comptes admin | Sécurité → Compte |
| Port SSH non standard | Terminal et SNMP |
| Mises à jour DSM planifiées | Panneau de configuration → Mise à jour |

### Outils CLI hors Package Center (optionnel)

**Entware** (`opkg`) : utile pour `tmux`, `jq`, `fail2ban`, etc. sans passer par le store. Architecture selon le CPU :

- Intel/AMD : [Entware — Install on Synology](https://github.com/Entware/Entware/wiki/Install-on-Synology-NAS) (script `x86_64-k3.2` ou `aarch64` selon modèle).

Nix **sur** le NAS est possible mais fragile (bind mount `/nix`, tâches au boot) — non requis pour ce workflow.

## Configuration locale (neo-nix)

```bash
cd hosts/nas
cp .env.example .env
# éditer NAS_HOST, NAS_USER, NAS_REMOTE_STACKS_DIR
ssh-copy-id -p "$NAS_SSH_PORT" "$NAS_USER@$NAS_HOST"
```

## Déployer les stacks

```bash
cd hosts/nas
nix run .#deploy
```

Une seule stack :

```bash
NAS_STACK=example nix run .#deploy
```

Le script :

1. `rsync` de `stacks/` vers le NAS ;
2. `docker compose up -d` dans chaque sous-dossier contenant un `docker-compose.yml`.

Sur le NAS, les conteneurs sont visibles dans **Container Manager** ; la source de vérité reste **git**.

## Ajouter un service

1. Créer `stacks/mon-service/docker-compose.yml`.
2. Volumes sur `/volume1/...` dans le compose (chemins **sur le NAS**).
3. Secrets : fichiers hors git sur le NAS, ou futur branchement **agenix** depuis neo-nix (rsync de fichiers `.age` déchiffrés au deploy) — à définir quand une stack en aura besoin.
4. `nix run .#deploy`.

## Dépannage

| Problème | Piste |
|----------|--------|
| `permission denied` docker | Utilisateur dans le groupe `docker` ou admin DSM ; sur certaines versions seul root/admin peut lancer docker |
| `docker not found` | Container Manager non installé / non démarré |
| `BatchMode=yes` échoue | Clé SSH manquante ou mauvais utilisateur |
| `rsync` supprime des fichiers distants | `--delete` synchronise exactement `stacks/` — données persistantes uniquement dans volumes Docker ou chemins hors `stacks/` |

## Relation avec le reste du dépôt

- Machines **NixOS** : `nixos/hosts/*` (ex. pi-sound).
- **NAS Synology** : `hosts/nas` (ce dossier).
