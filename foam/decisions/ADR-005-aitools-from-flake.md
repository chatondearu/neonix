# ADR-005 — Install ai-dev-kit from the flake input

- **Status**: accepted
- **Date**: 2026-11-25
- **Tags**: #architecture #ai #deployment

## Context

neo-nix consumed `cda.aitools` from `inputs.ai-dev-kit` but pointed `repoPath` at a local git checkout (`~/dev/chatondearu/ai-dev-kit`) and copied opencode skills from `dev/opencode/skills`. Cursor skills also drifted via `install.sh` against that clone. The clone lagged `origin/main`; the flake pin and the live skills could disagree.

## Decision

- Import kit `nix/maid.nix` with `repoPath = "${inputs.ai-dev-kit}"` into `users.users.chaton.maid`. Do **not** import `nixosModules.default` (`aiDevKit`): it re-imports a second nix-maid and conflicts with neo-nix's module.
- Do not pass a host checkout path to `cda.aitools.repoPath`.
- Set `cda.aitools.installMethod` and `graphify.installMethod` to `"nix"` (in-tree packages from the flake, no brew/uv fallback).
- Host-only extras overlay nix-maid from this repo. `cda-browser` lives in the kit (`skills/tools/cda-browser`); do not vendor kit skills here.

Update path: `nix flake update ai-dev-kit && sudo nixos-rebuild switch --flake .#neo-nix`.

## Alternatives considered

| Alternative | Why rejected |
| ----------- | ------------ |
| Keep `repoPath` on the local clone (`installMethod = auto`) | Skills follow an unsynced checkout, not the lockfile |
| Enable kit `nixosModules.default` (`aiDevKit`) | Re-imports nix-maid; option collision with neo-nix |
| Vendor kit skills under `dev/opencode/skills` | Second copy that rot; Cursor and opencode diverge |
| `install.sh` against the clone after each pin bump | Out-of-band, not atomic with the generation |

## Consequences

- **Positive**: one pin (`flake.lock`) drives packages, templates, and agent skills.
- **Negative**: skill edits require a kit commit + flake bump, not a live clone edit.
- **Constraint**: do not run `install.sh` against the real home for kit skills on this host.

## References

- `dev/aitools.nix`, `dev/ai.nix`
- Kit `nixosModules.default` / `nix/maid.nix`
