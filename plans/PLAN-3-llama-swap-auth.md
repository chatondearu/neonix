# PLAN-3 — Require auth for LAN llama-swap API

- **Status**: in-progress
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#3](https://github.com/chatondearu/neonix/issues/3)
- **Date**: 2026-10-15

## Summary

Add authentication so LAN-reachable llama-swap rejects unauthenticated callers while keeping port open for authorized clients.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #3 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [x] Choose smallest auth mechanism supported by llama-swap or a thin reverse proxy already in the stack
- [x] Wire secret via env/agenix; document client usage
- [x] Keep firewall 9292 only if still needed for LAN
- [x] Confirm unauthenticated /v1/models fails; authenticated succeeds
- [x] Ensure ADR-001 remains accurate

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [x] curl without credential → non-2xx
- [x] curl with credential → models list
- [x] No secret in git

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
