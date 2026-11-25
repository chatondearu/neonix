# ADR-004 — LUKS + LVM root layout with encrypted swap for hibernate

- **Status**: accepted
- **Date**: 2026-11-18
- **Tags**: #architecture #storage #deployment
- **Supersedes**: target partition table of [[ADR-003-nvme-system-migration|ADR-003]] (migration method in ADR-003 still stands)

## Context

The 1T replacement NVMe is large enough to split volumes and to size swap for hibernate. The current SanDisk layout cannot hibernate: disk swap is **8.8G** vs **32G RAM**, swap is **unencrypted**, `boot.resumeDevice` is unset (NixOS therefore passes `nohibernate`), and `nvidia-hibernate` is disabled after previous resume crashes.

A separate LUKS container (or `randomEncryption`) on swap is what actually breaks resume: the hibernate image is keyed for a volume the next boot cannot reopen. One unlock for root+swap avoids that without dropping encryption.

`/games` and `/hdd` stay on their current disks.

## Decision

On the new NVMe:

- GPT: **ESP 2G** (unencrypted FAT) + **one LUKS** covering the rest.
- Inside LUKS, **LVM vg0** with four ext4/swap volumes:

  | LV | Size | Mount |
  | -- | ---- | ----- |
  | `vg0-swap` | RAM + 16G (48G on this host) | swap, `boot.resumeDevice` |
  | `vg0-root` | 128G | `/` (`/var/tmp` is nix-daemon TMPDIR) |
  | `vg0-nix` | ~400G, adjust after measuring `/nix` | `/nix` |
  | `vg0-home` | remaining | `/home` |

- Keep **zram** (priority 5) for runtime; disk swap priority 1. Hibernate still writes to `vg0-swap`.
- Set `boot.resumeDevice = "/dev/mapper/vg0-swap"` and enable `nvidia-hibernate`.
- Set `security.protectKernelImage = false`: the option injects `nohibernate` and would cancel resume even with a sized encrypted swap.
- Reuse the current LUKS passphrase. Identify the new disk by model/serial, never `nvme0`/`nvme1`.

Agent procedure: `playbooks/nvme-root-migration.md`.

## Alternatives considered

| Alternative | Why rejected |
| ----------- | ------------ |
| Unencrypted swap partition (ADR-003 16G) | Hibernate image is a RAM dump (keys, secrets). Undersized for 32G RAM |
| `randomEncryption` on swap | New key every boot; resume is impossible |
| Second LUKS on swap | Two unlocks or a keyfile chicken-and-egg in initrd |
| Swapfile on ext4 | `resume_offset` breaks if the file is recreated; extra moving part |
| One ext4 `/` (no split) | A reinstall or a full `/nix` wipes `/home` on a 1T disk we can afford to split |
| Btrfs subvolumes | Filesystem change in the same move as the disk; current root is ext4 |
| Drop LUKS | Solves nothing that LVM-on-LUKS does not; weakens rest-at-rest |

## Consequences

- **Positive**: One passphrase; hibernate image is encrypted; `/home` and `/nix` survive a root reinstall; swap ≥ RAM.
- **Negative**: LVM + four mounts in `hardware-configuration.nix`. NVIDIA Wayland resume can still hang — test after the disk move, SanDisk still installed.
- **Constraint**: Hibernate needs `protectKernelImage = false` (otherwise `nohibernate` stays on the cmdline). Kernel param changes apply only after reboot.

## References

- `playbooks/nvme-root-migration.md`
- `hardware-configuration.nix`, `system/system.nix`, `system/gpu.nix`
- [[ADR-003-nvme-system-migration|ADR-003]]
- [[../architecture/nvme-system-migration|NVMe system migration]]
