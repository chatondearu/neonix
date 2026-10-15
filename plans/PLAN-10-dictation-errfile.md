# PLAN-10 — Write STT errors under runtime state dir

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#10](https://github.com/chatondearu/neonix/issues/10)
- **Date**: 2026-10-15

## Summary

Move dictation transcription error file from fixed /tmp path into the runtime state dir.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #10 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Use STATE_DIR (or equivalent) for the err file
- [ ] Update tests if they assert the old path

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] Existing dictation-ptt tests pass

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
