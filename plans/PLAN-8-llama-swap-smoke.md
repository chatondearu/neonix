# PLAN-8 — Smoke assert unauthenticated llama-swap rejection

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#8](https://github.com/chatondearu/neonix/issues/8)
- **Date**: 2026-10-15

## Summary

Add regression check that fails if llama-swap is usable without auth on the LAN port. Blocked by #3.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #8 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Add assert/smoke step for unauthenticated rejection
- [ ] Wire into safe-update or existing wayland smoke when practical
- [ ] Passes after #3 is merged/applied

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] Script fails on open unauthenticated API
- [ ] Script passes when auth is required

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
