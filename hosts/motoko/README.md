# Motoko prod — runbook neo-nix (session agent)

Configuration **workstation** (neo-nix) + opérations **serveur** Debian Motoko via SSH. Le code plateforme vit dans **[motoko-ops](https://github.com/chatondearu/motoko-ops)** (dépôt privé).

**Machine locale :** flake `neo-nix` (`~/etc/nixos`).  
**Serveur :** hostname `motoko`, SSH **root par clé uniquement** (pas de mot de passe).

---

## Démarrer une nouvelle session Cursor (copier-coller)

```text
Contexte neo-nix : ~/etc/nixos/hosts/motoko/README.md

Objectif : bootstrap production Motoko (PLAN-002 slice 1+), coexistence Coolify.
SSH validé : ssh -p 2242 motoko-prod 'hostname; id -un'

Lire :
1. ~/etc/nixos/hosts/motoko/README.md (ce fichier)
2. /hdd/dev/neomatix/motoko-ops/docs/runbooks/production-motoko-checklist.md
3. /hdd/dev/neomatix/motoko-ops/plans/PLAN-002-production-bootstrap.md

Règles :
- Pas de secrets dans le chat (SOPS / tokens / clés privées).
- Pas de bascule DNS staging ni coupure SSH public sans confirmation explicite.
- Serveur : root, pas de sudo.

Commencer par : ./hosts/motoko/scripts/smoke-ssh.sh puis audit read-only sur motoko-prod.
```

---

## Prérequis neo-nix

| Élément | Statut attendu |
|--------|----------------|
| Alias SSH `motoko-prod` | `~/.ssh/config` ou `programs.ssh` NixOS |
| Port | **2242** (pare-feu neo-nix / forwarding selon ton setup) |
| Clé | ed25519 dédiée bootstrap (fichier ou agenix, voir ci-dessous) |
| Checkout motoko-ops | ex. `/hdd/dev/neomatix/motoko-ops` |
| `gh` authentifié | clone/push repo privé depuis le laptop |

### Smoke SSH (local)

```bash
cd ~/etc/nixos
./hosts/motoko/scripts/smoke-ssh.sh
```

Attendu : `motoko`, `root`, `root_writable_ok`.

---

## SSH déclaratif + agenix (optionnel, recommandé)

Pattern identique à `system/secrets.nix` (`llama-swap-api-key`) :

1. Générer une clé **bootstrap** (une fois) :  
   `ssh-keygen -t ed25519 -f /tmp/motoko_cursor_bootstrap -N "" -C "motoko-cursor-bootstrap"`
2. Publique → déjà sur Motoko `/root/.ssh/authorized_keys` (fait si smoke OK).
3. Privée → chiffrer :  
   `cat /tmp/motoko_cursor_bootstrap | agenix -e secrets/motoko-cursor-ssh-key.age`  
   Puis ajouter dans `secrets/secrets.nix` + `system/secrets.nix` (voir [module example](./motoko-ssh.nix.example)).
4. Importer `dev/motoko-ssh.nix` (copie depuis example), `neo.motoko.enable = true`, hostname/port.
5. `sudo nixos-rebuild switch --flake .#neo-nix`

Variables pour motoko-ops / Cursor (`motoko-ops/.envrc.local`, gitignored) :

```bash
export MOTOKO_SSH_HOST=motoko-prod
export MOTOKO_SSH_USER=root
export MOTOKO_SSH_IDENTITY_FILE=/run/agenix/motoko-cursor-ssh-key   # si agenix
# ou : export MOTOKO_SSH_IDENTITY_FILE=~/.ssh/motoko_cursor_bootstrap
export MOTOKO_SSH_STRICT_HOST_KEY=accept-new
export MOTOKO_OPS_ROOT=/opt/motoko
```

Helper SSH avec port : `hosts/motoko/scripts/ssh-motoko.sh`.

---

## Déployer motoko-ops sur le serveur

Dépôt **privé** : pas de `curl raw.githubusercontent.com` sans token.

### Option A — rsync depuis neo-nix (simple)

```bash
cd /hdd/dev/neomatix/motoko-ops   # chemin réel du checkout
./hosts/motoko/scripts/rsync-to-motoko.sh
```

### Option B — git sur Motoko (deploy key)

Sur Motoko (root), deploy key read-only GitHub → puis :

```bash
ssh -p 2242 motoko-prod 'git clone --branch main --depth 1 git@github.com:chatondearu/motoko-ops.git /opt/motoko'
```

### Install production (sur le serveur)

```bash
ssh -p 2242 motoko-prod '/opt/motoko/scripts/install-motoko.sh --profile production --skip-clone'
```

Dry-run d’abord :

```bash
ssh -p 2242 motoko-prod '/opt/motoko/scripts/install-motoko.sh --profile production --skip-clone --dry-run'
```

---

## Audit read-only (agent — première connexion)

```bash
ssh -p 2242 motoko-prod 'set -e
hostname; uname -a; id -un
df -h / /opt 2>/dev/null || df -h /
command -v docker && docker version --format "{{.Server.Version}}" || echo no-docker
command -v nomad && nomad version || echo no-nomad
ss -lntp | head -30
test -d /opt/motoko && ls -la /opt/motoko | head -5 || echo no-opt-motoko
'
```

---

## Enchaînement V1 (rappel)

| Étape | Plan | Où |
|-------|------|-----|
| Bootstrap host + Nomad | PLAN-002 s1–s5 | Serveur |
| Mesh Headscale | PLAN-002 s2 | Serveur + DNS |
| SOPS + motoko-agent | PLAN-002 s3 | Serveur + laptop |
| Observabilité | PLAN-003 | Serveur |
| BAJO staging | PLAN-004 | Serveur |
| Backups drill | PLAN-005 | Serveur |

Checklist détaillée : motoko-ops `docs/runbooks/production-motoko-checklist.md`.

---

## Retrait clé bootstrap

Après mesh + `motoko-agent` :

1. Retirer la ligne clé bootstrap de `/root/.ssh/authorized_keys` sur Motoko.
2. Désactiver `neo.motoko` / secret agenix sur neo-nix ; rebuild.

---

## Fichiers de ce dossier

| Fichier | Rôle |
|---------|------|
| [scripts/smoke-ssh.sh](./scripts/smoke-ssh.sh) | Vérif SSH depuis neo-nix |
| [scripts/ssh-motoko.sh](./scripts/ssh-motoko.sh) | Wrapper `ssh -p 2242` |
| [scripts/rsync-to-motoko.sh](./scripts/rsync-to-motoko.sh) | Sync checkout → `/opt/motoko` |
| [motoko-ssh.nix.example](./motoko-ssh.nix.example) | Module NixOS + agenix (à activer) |
| [.env.example](./.env.example) | Variables opérateur (copier en `.env`, gitignored) |
