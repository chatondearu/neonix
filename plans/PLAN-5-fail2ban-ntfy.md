# PLAN-5 — Stop fail2ban public ntfy topic

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#5](https://github.com/chatondearu/neonix/issues/5)
- **Date**: 2026-10-15

## Summary

Remove public ntfy.sh/Fail2banNotifications action; use private topic/token or safe no-op.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #5 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Remove public topic URL from fail2ban action
- [ ] Wire private topic/token from secret/env OR disable remote notify safely
- [ ] If credentials missing, safe no-op + BLOCKED report

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] Grep shows no public Fail2banNotifications URL
- [ ] Action config still valid for fail2ban

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
