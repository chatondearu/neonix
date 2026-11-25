# NVMe system migration (neo-nix)

- **Status**: done
- **Date**: 2026-11-18 (moved 2026-11-25)
- **Tags**: #architecture #deployment #storage
- **Method**: [[../decisions/ADR-003-nvme-system-migration|ADR-003]]
- **Layout**: [[../decisions/ADR-004-luks-lvm-hibernate|ADR-004]]
- **Steps**: [`playbooks/nvme-root-migration.md`](../../playbooks/nvme-root-migration.md)

## Layout (2026-11-25)

NixOS boots from the **WD_BLACK SN850X 1T**. SanDisk fallback was wiped the same day (empty spare, still plugged; identify by serial only). `nvme0`/`nvme1` index can swap across boots.

| Disk | Model / serial | Role |
| ---- | -------------- | ---- |
| WD_BLACK SN850X 1000GB `255193400899` | ~931.5G | LUKS `cryptroot` → LVM `vg0` (system) |
| SanDisk SSD PLUS 480GB `1948B0800288` | 447G | Empty spare (GPT zapped, no ESP) |
| FOX SPIRIT PM18 960GB `01262221B0121` | ~894G | `/games` |
| ST2000DM008-2FR102 `ZFL5Q771` | 1.8T | `/hdd` |

`vg0`: `swap` 48G (`boot.resumeDevice`), `root` 128G (`/`), `nix` 400G, `home` remainder. ESP UUID `FDAA-6D1C`. LUKS UUID `050154d3-4c03-437f-9bcf-1835591af470`. zram stays (priority 5). `nvidia-hibernate` on.

## Target on the 1T NVMe (ADR-004)

ESP 2G + one LUKS + LVM `vg0`: `swap` 48G, `root` 128G (`/`), `nix` ~400G, `home` remainder. Encrypted swap is the resume device. `/games` and `/hdd` unchanged.

Agent steps stay in the playbook (single source).
