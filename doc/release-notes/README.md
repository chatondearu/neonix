# Flake Update Release Notes

This directory stores one note per lockfile update.

## Rule

If `flake.lock` changes, add or update at least one file in `doc/release-notes/`.

## Create a new note

```sh
bash /home/chaton/etc/nixos/scripts/new-flake-release-note.sh
```

Optional custom suffix:

```sh
bash /home/chaton/etc/nixos/scripts/new-flake-release-note.sh quickshell-sync
```

## Filename convention

- `YYYY-MM-DD-flake-update.md`
- `YYYY-MM-DD-<short-topic>.md`

## Content

Start from `doc/flake-update-release-notes-template.md` and keep all validation sections filled:

- build/switch status
- smoke tests status
- Wayland/XWayland/Gaming checks
- rollback decision
