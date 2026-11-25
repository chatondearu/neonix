# ADR-003 — Migrate neo-nix root from SATA SSD to a new NVMe

- **Status**: accepted
- **Date**: 2026-11-18
- **Tags**: #architecture #deployment #storage
- **Layout**: partition sizes in this ADR are superseded by [[ADR-004-luks-lvm-hibernate|ADR-004]] (LUKS+LVM, hibernate). The copy method below still stands.

## Context

neo-nix currently boots from a SATA SanDisk 480G SSD (LUKS + ext4 `/`, FAT `/boot`, unencrypted swap). A 240G NVMe holds an unused Windows install. A new, larger NVMe will replace the Windows stick; the NixOS root, home, `/nix`, `/var`, and swap should move onto it.

`/` already uses ~284G, so the 240G Windows NVMe cannot host the system. `/games` (FOX SPIRIT 960G) and `/hdd` (2T HDD) stay where they are.

## Decision

- Replace **only** the LDLC 240G Windows NVMe with the new drive. Leave the SanDisk, games NVMe, and HDD connected until the new root has booted successfully.
- Create **new GPT partitions and new UUIDs** on the replacement NVMe. Do not block-clone the SanDisk while both disks are present. Target volumes: [[ADR-004-luks-lvm-hibernate|ADR-004]].
- Copy the live root with **rsync** (exclude `/games`, `/hdd`, and pseudo-fs), then `nixos-install --flake .#neo-nix` so Limine lands on the new ESP.
- Update `hardware-configuration.nix` (LUKS `/`, `/boot`) and `swapDevices` in `system/system.nix` **before** first boot from the NVMe. Identify disks by model/serial, never by `nvme0`/`nvme1` index.
- Keep the SanDisk as fallback until several successful boots; wipe it later.

Steps: `playbooks/nvme-root-migration.md`. Snapshot: [[../architecture/nvme-system-migration|NVMe system migration]].

## Alternatives considered

| Alternative | Why rejected |
| ----------- | ------------ |
| `dd` / Clonezilla of `sda` onto the new NVMe | Duplicate LUKS/ESP UUIDs while the SanDisk stays connected; initrd would unlock the old disk |
| Fresh `nixos-install` without rsync | Drops `/home`, `/var`, SSH host keys, Tailscale identity |
| Put NixOS on the existing 240G Windows NVMe | Too small (~284G used on `/`) |
| Move `/games` or `/hdd` in the same pass | Out of scope; they already have stable `partuuid` / labels |

## Consequences

- **Positive**: New UUIDs let both disks stay plugged in; SanDisk remains a working rollback.
- **Negative**: Must edit generated hardware UUIDs and reinstall the bootloader; ~284G rsync.
- **Constraint**: First firmware boot from the new NVMe must happen only after the flake points at the new UUIDs. Secure Boot is currently disabled; `sbctl` re-enrolment is not part of this move.

## References

- `hardware-configuration.nix`
- `system/system.nix` (`swapDevices`, `zramSwap`)
- `system/boot.nix` (`/games`, `/hdd`, Limine)
- [[../architecture/nvme-system-migration|NVMe system migration]]
