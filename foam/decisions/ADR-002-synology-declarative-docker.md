# ADR-002 — Synology NAS declarative via Docker stacks

- **Status**: accepted
- **Date**: 2026-03-25
- **Tags**: #deployment #architecture #security

## Context

The Synology NAS should be operated like the rest of the homelab: versioned config, deploy from neo-nix, minimal reliance on Synology Package Center for application software. DSM cannot run NixOS; installing Nix on DSM is possible but brittle across DSM updates.

## Decision

- Keep **DSM** as the NAS operating system.
- Store declarative **Docker Compose stacks** under `hosts/nas/stacks/`.
- Deploy with **SSH + rsync + `docker compose`** via `nix run .#deploy` from `hosts/nas`.
- Use **Container Manager** (Docker engine on DSM) as the only Synology “app” required for workloads; install via `synopkg` or manual `.spk` when the store UI is avoided.
- Document bootstrap and security in `hosts/nas/README.md`.

## Alternatives considered

| Alternative | Why rejected |
| ----------- | ------------ |
| NixOS on the NAS | Not supported; would replace DSM |
| Nix package manager on DSM | High maintenance; boot bind-mounts; DSM upgrades risk |
| Synology Package Center per app | Opaque versions, not in git, duplicates Docker stacks |
| Ansible on DSM | Viable; Nix flake already used elsewhere in repo |

## Consequences

- **Positive**: Single git source of truth; same mental model as other flakes; apps are standard containers.
- **Negative**: DSM-specific bootstrap (synopkg, permissions) stays manual/scripted, not `nixos-rebuild`.
- **Constraint**: Secrets for stacks need a follow-up pattern (agenix rsync or NAS-side files).

## References

- `hosts/nas/`
- [[../index|Project memory]]
