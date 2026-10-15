# PRD-2 — Harden neo-nix from KISS audit

- **Status**: approved
- **GitHub**: [#2](https://github.com/chatondearu/neonix/issues/2)
- **Date**: 2026-10-15
- **Tags**: #product #security #infra

## Problem

A KISS audit of the neo-nix NixOS flake found concrete host risks: an unauthenticated LAN-open LLM API, passwordless wheel sudo, a public fail2ban ntfy topic, dead opencode skill symlinks, unused firewall openings, missing regression coverage for the LLM exposure, and a few smaller hygiene issues.

## Goals

- [ ] llama-swap stays usable from the LAN **with authentication** (option B from GO)
- [ ] Wheel sudo requires a password again
- [ ] fail2ban does not post to a public ntfy topic
- [ ] opencode `task-management` skill resolves; dead `*.bak-*` links are gone
- [ ] Unused firewall ports / wide UDP range are removed
- [ ] A smoke/assert fails if llama-swap is usable without auth again
- [ ] `.gitignore` covers `*.bak-*`
- [ ] Dictation STT error file is under the runtime state dir
- [ ] Global `ip_forward` is off unless an explicit module needs it

## Non-goals

- Sunshine pairing redesign
- VR stack rewrite
- Raspberry / pi-sound hosts
- STT stack rewrite
- Auto-merge of PRs
- Binding llama-swap to localhost-only (rejected — option A)

## Users & scenarios

| Persona | Scenario |
| ------- | -------- |
| Workstation owner | Applies nixos-rebuild; LAN clients call llama-swap with a secret; strangers cannot |
| Compromised user process | Cannot silently escalate to root without sudo password |
| Coding agent | Loads opencode skills without broken symlink errors |

## Requirements

### Functional

- [ ] Unauthenticated HTTP to llama-swap on `:9292` is rejected; authenticated clients succeed
- [ ] Secret provisioned via env/agenix — never committed
- [ ] `sudo` / `sudo-rs` require password for wheel
- [ ] fail2ban action uses private topic/token or safe no-op
- [ ] Firewall drops 8009/8080/9000 and UDP 32768–61000 unless a named live service needs them
- [ ] Smoke check covers unauthenticated rejection (after auth child)

### Non-functional

- [ ] One child issue = one PR; Conventional Commits; English artifacts
- [ ] Smallest complete change per child (KISS)
- [ ] Format Nix with alejandra when touching `.nix`

## Related project memory

- ADRs: [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]]
- Product: [[../foam/product/vision|vision]]

## Open questions

1. Private ntfy topic/token for #5 — worker may BLOCKED until provided
2. Confirm whether Docker/VPN still needs `ip_forward` before #11 ships

## Success metrics

- All nine children have mergeable PRs with green CI (or documented BLOCKED)
- Live check: unauthenticated `curl` to LAN `:9292/v1/models` fails; authenticated succeeds

## Implementation pointer

Per-child plans under `plans/PLAN-<child#>-*.md`
