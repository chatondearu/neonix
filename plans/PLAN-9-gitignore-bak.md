# PLAN-9 — Ignore bak-* skill backup links

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#9](https://github.com/chatondearu/neonix/issues/9)
- **Date**: 2026-10-15

## Summary

Extend .gitignore so *.bak-* matches skill backup symlink names.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #9 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Add *.bak-* next to *.bak
- [ ] Confirm bak-* paths are ignored

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] git check-ignore on a bak-* path succeeds

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
