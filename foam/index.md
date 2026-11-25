# Project memory

Map of Content (MOC). Start here before product or architecture decisions.

## How to use

1. **New feature** → `cda-prd` → `prd/PRD-NNN-slug.md`, link ADRs.
2. **Implementation** → `cda-plan` → `plans/PLAN-NNN-slug.md`.
3. **Technical choice** → `foam/decisions/ADR-NNN-slug.md`.
4. **Sync kanban** → `import-kanban.sh` refreshes [[features/shipped|shipped]] / [[features/backlog|backlog]].

## Product

- [[product/vision|Vision & positioning]]

## Features

- [[features/index|Feature catalog]]
- [[features/shipped|Shipped]]
- [[features/backlog|Backlog]]

## Architecture

- [[architecture/nvme-system-migration|NVMe system migration]] — layout snapshot; steps in `playbooks/nvme-root-migration.md` ([[decisions/ADR-003-nvme-system-migration|ADR-003]], [[decisions/ADR-004-luks-lvm-hibernate|ADR-004]])

## Decisions (ADRs)

Index: [[decisions/index|All ADRs]]

- [[decisions/ADR-001-llama-swap-lan-auth|ADR-001]] — llama-swap LAN + auth (accepted)
- [[decisions/ADR-002-synology-declarative-docker|ADR-002]] — Synology NAS declarative Docker stacks (accepted)
- [[decisions/ADR-003-nvme-system-migration|ADR-003]] — migrate neo-nix root to a new NVMe (accepted)
- [[decisions/ADR-004-luks-lvm-hibernate|ADR-004]] — LUKS+LVM + encrypted swap for hibernate (accepted)
- [[decisions/ADR-005-aitools-from-flake|ADR-005]] — ai-dev-kit from flake input (`nix/maid.nix`), not a local clone (accepted)
- [[decisions/ADR-006-ptt-streaming-whisper-stream|ADR-006]] — PTT streaming STT via whisper-stream (accepted)

## PRDs & plans

| PRD | Status |
| --- | ------ |
| [[../prd/PRD-2-kiss-audit-harden\|PRD-2]] | approved |
| [[../prd/PRD-29-dictation-ptt-quiet-streaming\|PRD-29]] | approved |

- PRD template: `prd/template.md`
- Plan template: `plans/template.md`

## Tags

`#product` `#architecture` `#deployment` `#data` `#auth` `#storage`
