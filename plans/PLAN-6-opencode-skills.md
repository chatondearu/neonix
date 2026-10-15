# PLAN-6 — Repair task-management and remove dead bak links

- **Status**: draft
- **PRD**: [[../prd/PRD-2-kiss-audit-harden|PRD-2]]
- **GitHub**: [#6](https://github.com/chatondearu/neonix/issues/6)
- **Date**: 2026-10-15

## Summary

Restore a readable task-management skill and delete broken *.bak-* symlinks under dev/opencode/skills.

## Constraints (from ADRs)

| ADR | Constraint |
| --- | ---------- |
| [[../foam/decisions/ADR-001-llama-swap-lan-auth|ADR-001]] | LAN llama-swap must use auth (not localhost-only); secrets not committed |

Do not violate accepted ADRs without superseding them.

## Scope

### In scope

- Deliver acceptance criteria on issue #6 only

### Out of scope

- Other epic children; Sunshine/VR/pi hosts

## Technical approach

Smallest NixOS/config/script change that meets acceptance. Discover paths at implement time.

## Tasks

- [ ] Replace broken task-management symlink with real skill content (copy from ~/.cursor/skills or kit)
- [ ] Remove all *.bak-* skill symlinks in that tree
- [ ] Verify rg and SKILL.md resolve

## Risks & mitigations

| Risk | Mitigation |
| ---- | ---------- |
| Scope creep into other findings | One issue = one PR |
| Missing secrets | Report BLOCKED; leave safe default |

## Test plan

- [ ] test -f dev/opencode/skills/task-management/SKILL.md
- [ ] rg over skills tree exits 0

## Verification

- [ ] Lint / test / build per AGENTS.md (alejandra for Nix; existing script tests if touched)
- [ ] Update foam / ADR if a new decision was made
