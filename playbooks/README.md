# Playbooks

Runbooks an agent (or human) executes on the live neo-nix host. English. One file per job.

| Playbook | When |
| -------- | ---- |
| [nvme-root-migration.md](nvme-root-migration.md) | **Done.** Historical: moved root onto the 1T NVMe (LUKS+LVM, hibernate). SanDisk fallback wiped 2026-11-25. |

Decisions live in `foam/decisions/`. These files are the **steps**.
