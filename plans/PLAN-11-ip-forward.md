# PLAN-11 — Disable ip_forward unless needed

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#11](https://github.com/chatondearu/neonix/issues/11)
- **Date**: 2026-10-15

## Summary

Turn off global IPv4 forwarding unless an explicit module justifies it.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #11 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Determine if Docker/VPN currently requires ip_forward
- [ ] Default to 0 or gate behind explicit option with comment
- [ ] Document consequence

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] Config evaluates; sysctl intent clear in module

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
