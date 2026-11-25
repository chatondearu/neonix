# Playbooks

Runbooks an agent (or human) executes on the live neo-nix host. English. One file per job.

| Playbook | When |
| -------- | ---- |
| [nvme-root-migration.md](nvme-root-migration.md) | Replacement 1T NVMe is installed; machine has booted the **SanDisk** NixOS. Moves root/home/nix/swap onto the new disk (LUKS+LVM, hibernate). |

Decisions live in `foam/decisions/`. These files are the **steps**.
