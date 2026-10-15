# PLAN-7 — Drop unused firewall ports and wide UDP range

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#7](https://github.com/chatondearu/neonix/issues/7)
- **Date**: 2026-10-15

## Summary

Remove unused 8009/8080/9000 and UDP 32768-61000 while keeping SSH and intentional gaming/streaming ports.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #7 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Confirm no live service needs the dead openings
- [ ] Remove them from networking.firewall
- [ ] Keep 2242 and active streaming/VR/Sunshine rules

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] Config evaluates
- [ ] Document any kept exception

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
