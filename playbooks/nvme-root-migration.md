# Playbook — migrate neo-nix root to the 1T NVMe

For an agent on the live host after the next NixOS boot. English. Do the steps in order. Each step ends on a checkable done line. Chat with the human in French.

- **Status**: done (SanDisk fallback wiped 2026-11-25; disk left plugged as empty spare)
- **ADRs**: [[../foam/decisions/ADR-003-nvme-system-migration|ADR-003]] (method) + [[../foam/decisions/ADR-004-luks-lvm-hibernate|ADR-004]] (layout)
- **Layout snapshot**: [[../foam/architecture/nvme-system-migration|foam architecture note]]

## When to run

The LDLC 240G Windows NVMe is **already replaced** by the ~1T drive. The machine booted **NixOS from the SanDisk SATA** (`sda`). You are in `/home/chaton/etc/nixos`.

If the new NVMe is not in `lsblk`, stop and tell the human to fit the drive first.

## Hard rules

- Identify disks by **model + serial**, never by `nvme0` / `nvme1`.
- Write partitions only on the new ~1T NVMe. SanDisk `sda`, FOX SPIRIT `/games`, and HDD `sdb` stay mounted and unformatted.
- Copy with **rsync**. Do not `dd` / Clonezilla (duplicate UUIDs while SanDisk is present).
- Session 1: `nixos-install --root /mnt` only. **No** `nixos-rebuild switch` until session 2 (booted from the new NVMe).
- One LUKS passphrase, prompted from the human; reuse the current one.

## Target (ADR-004)

```
NEW_NVME GPT
  p1  2G     EF00  FAT32  /boot
  p2  rest   8309  LUKS → mapper cryptroot → LVM vg0
        vg0-swap  RAM+16G (48G here)  swap + boot.resumeDevice
        vg0-root  128G                /
        vg0-nix   ~400G               /nix   (measure, then size)
        vg0-home  remaining           /home
```

`/games` and `/hdd` keep their current devices. zram stays (priority 5). Disk swap priority 1.

---

# Session 1 — SanDisk still boots the running system

## 0. Tools

Need `sgdisk`, `cryptsetup`, `pvcreate`, `rsync`, `mkfs.fat`, `mkfs.ext4`, `mkswap` on PATH. If any is missing:

```bash
nix-shell -p gptfdisk cryptsetup lvm2 rsync dosfstools e2fsprogs util-linux
```

**Done:** each command prints a version or help.

## 1. Preflight — abort if any check fails

Run:

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,UUID,PARTUUID,MOUNTPOINT,MODEL,SERIAL
findmnt / /boot /home /nix /games /hdd
cat /proc/cmdline
swapon --show
free -h
```

Abort unless all of these are true:

| Check | Expect |
| ----- | ------ |
| `/` is the SanDisk LUKS ext4 | mapper `luks-97c4ccff-…`, ~430G |
| `/boot` is `sda1` | UUID `FD17-0AAA` |
| FOX SPIRIT 960G is mounted `/games` | serial `01262221B0121` |
| HDD `sdb` is mounted `/hdd` | serial `ZFL5Q771` |
| A ~1T NVMe exists | **not** FOX SPIRIT, **not** SanDisk, size ~931–1024G |
| That 1T disk has **no** mounted filesystems | empty or unused partitions only |
| LDLC 240G Windows is **gone** | serial `12062219L0463` absent |

Export the 1T node once, and use only this variable afterwards:

```bash
NEW=$(lsblk -dno NAME,SIZE,MODEL,SERIAL | awk '/[Tt][Bb]|931G|1024G|953G|894G/ {print}' )
# then set NEW=/dev/nvmeXn1 by serial/model match; confirm with lsblk $NEW
```

**Done:** `echo $NEW` is one disk, ~1T, unmounted, model/serial recorded in the session notes.

## 2. Measure source sizes

```bash
du -xsb /nix /home /var | awk '{printf "%s %.1fG\n", $2, $1/1024/1024/1024}'
```

Size LVs (GiB):

- `SWAP_G` = RAM GiB + 16 → **48** on this host
- `ROOT_G` = **128** (nix-daemon `TMPDIR=/var/tmp`)
- `NIX_G` = `/nix` used + **150**, minimum 400
- `HOME_G` = remainder of the LUKS VG

Abort if `HOME_G` < `/home` used + 50, or `NIX_G` < `/nix` used + 80. Ask the human; do not shrink below those floors.

**Done:** four numbers `SWAP_G ROOT_G NIX_G HOME_G` written down; they fit on the VG.

## 3. HUMAN — LUKS passphrase

Ask the human to type the passphrase they want (same as today’s SanDisk LUKS). Do not invent one. Do not store it in the repo.

**Done:** human is at the terminal ready for `cryptsetup luksFormat` prompts.

## 4. Partition and LUKS

Double-check `$NEW` one last time (`lsblk $NEW` has no `/` `/boot` `/games` `/hdd`). Then:

```bash
sgdisk --zap-all "$NEW"
sgdisk -n1:0:+2G  -t1:EF00 -c1:ESP \
       -n2:0:0    -t2:8309 -c2:cryptroot \
       "$NEW"
partprobe "$NEW"
sleep 2
mkfs.fat -F32 -n ESP "${NEW}p1"
cryptsetup luksFormat "${NEW}p2"
cryptsetup open "${NEW}p2" cryptroot
```

**Done:** `lsblk "$NEW"` shows `p1` vfat and `p2` with mapper `cryptroot`.

## 5. LVM + filesystems

```bash
pvcreate /dev/mapper/cryptroot
vgcreate vg0 /dev/mapper/cryptroot
lvcreate -L ${SWAP_G}G -n swap vg0
lvcreate -L ${ROOT_G}G -n root vg0
lvcreate -L ${NIX_G}G  -n nix  vg0
lvcreate -l 100%FREE   -n home vg0

mkswap -L swap /dev/vg0/swap
mkfs.ext4 -L nixos /dev/vg0/root
mkfs.ext4 -L nix   /dev/vg0/nix
mkfs.ext4 -L home  /dev/vg0/home
```

**Done:** `lvs -o lv_name,vg_name,lv_size` lists `swap root nix home` on `vg0`.

## 6. Mount target

```bash
mount /dev/vg0/root /mnt
mkdir -p /mnt/{boot,home,nix}
mount "${NEW}p1" /mnt/boot
mount /dev/vg0/home /mnt/home
mount /dev/vg0/nix /mnt/nix
findmnt /mnt /mnt/boot /mnt/home /mnt/nix
```

**Done:** four mounts, all on `vg0-*` or the new ESP, nothing on SanDisk under `/mnt`.

## 7. Copy

Stop heavy writers, then rsync. Resume them after the copy.

```bash
systemctl stop nix-daemon || true

rsync -aAXh --info=progress2 --numeric-ids \
  --exclude='/dev/*' --exclude='/proc/*' --exclude='/sys/*' \
  --exclude='/tmp/*' --exclude='/run/*' --exclude='/mnt/*' \
  --exclude='/media/*' --exclude='/lost+found' \
  --exclude='/boot/*' --exclude='/home/*' --exclude='/nix/*' \
  --exclude='/hdd/*' --exclude='/games/*' \
  / /mnt/

rsync -aAXh --info=progress2 --numeric-ids /home/ /mnt/home/
rsync -aAXh --info=progress2 --numeric-ids /nix/  /mnt/nix/
rsync -aAXh --info=progress2 --numeric-ids /boot/ /mnt/boot/

systemctl start nix-daemon || true
```

**Done:** `du -s /mnt /mnt/home /mnt/nix /mnt/boot` are in the same ballpark as the sources; `/mnt/home/chaton` exists; `/mnt/nix/store` is populated.

## 8. UUIDs

```bash
lsblk -o NAME,UUID,PARTUUID,LABEL,MOUNTPOINT "$NEW"
cryptsetup luksUUID "${NEW}p2"
findmnt -no UUID /mnt/boot
```

Record:

- `LUKS_UUID` — LUKS of p2
- `ESP_UUID` — FAT of p1

**Done:** both UUIDs are non-empty and **different** from SanDisk (`97c4ccff-…`, `FD17-0AAA`).

## 9. Point the flake at vg0 (live repo)

Edit **this git repo** (`/home/chaton/etc/nixos`). Do not `nixos-rebuild switch`.

### 9a. `hardware-configuration.nix`

Keep `boot.initrd.availableKernelModules` (must include `"nvme"`). Replace only the filesystem / LUKS / swap stanza with:

```nix
  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/LUKS_UUID";

  fileSystems."/" = {
    device = "/dev/mapper/vg0-root";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/vg0-nix";
    fsType = "ext4";
  };

  fileSystems."/home" = {
    device = "/dev/mapper/vg0-home";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/ESP_UUID";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # swapDevices live in system/system.nix
```

Substitute the real UUIDs. Leave `nixpkgs.hostPlatform` and CPU microcode lines.

You may run `nixos-generate-config --root /mnt` and **merge** those four `fileSystems` + `luks.devices` into the repo file. Do not replace the whole flake with the generated tree. Do not copy a `swapDevices` block from the generated file into `hardware-configuration.nix`.

### 9b. `system/system.nix` — swap + resume

Replace `swapDevices` with:

```nix
  boot.resumeDevice = "/dev/mapper/vg0-swap";

  swapDevices = [
    {
      device = "/dev/mapper/vg0-swap";
      priority = 1;
    }
  ];
```

Leave `zramSwap` as it is (priority 5).

### 9c. `system/gpu.nix` — NVIDIA hibernate hook

Set:

```nix
  systemd.services.nvidia-hibernate.enable = true;
```

(`nvidia-suspend` and `nvidia-resume` stay enabled.)

### 9d. Sync the flake onto the new disk

```bash
rsync -aAXh /home/chaton/etc/nixos/ /mnt/home/chaton/etc/nixos/
```

**Done:** `rg -n 'vg0-swap|cryptroot|nvidia-hibernate.enable' hardware-configuration.nix system/system.nix system/gpu.nix /mnt/home/chaton/etc/nixos/system/*.nix` shows the new values on both copies. SanDisk UUIDs `97c4ccff` and `FD17-0AAA` are gone from `fileSystems` / `luks.devices` / `swapDevices`.

## 10. Install Limine on the **new** ESP

```bash
sudo nixos-install --root /mnt --flake /home/chaton/etc/nixos#neo-nix --no-root-passwd
```

**Done:** command exits 0; `/mnt/boot` contains Limine EFI files; `lsblk` still shows `/` on the SanDisk mapper (running system unchanged).

## 11. Stop — human firmware

Unmount is optional; a reboot will drop `/mnt`.

Tell the human (French):

1. Reboot into firmware (UEFI boot menu).
2. Set the **1T NVMe** as first boot device. Leave the SanDisk in the machine.
3. Unlock LUKS with the passphrase used in step 4.
4. After login, start this playbook at **Session 2**.

Do not wipe the SanDisk. Do not run `nixos-rebuild switch` on this generation.

**Done:** human has the four bullets; session 1 ends.

---

# Session 2 — booted from the 1T NVMe

## 12. Prove we are on the new root

```bash
findmnt / /boot /home /nix /games /hdd
lsblk -o NAME,SIZE,LABEL,MOUNTPOINT,MODEL,SERIAL
cat /proc/cmdline
swapon --show
df -h / /boot /home /nix
```

**Done** only if all match:

| Mount | Device |
| ----- | ------ |
| `/` | `vg0-root` |
| `/home` | `vg0-home` |
| `/nix` | `vg0-nix` |
| `/boot` | new ESP (UUID ≠ `FD17-0AAA`) |
| `/games` | FOX SPIRIT |
| `/hdd` | HDD `sdb` |
| cmdline | contains `resume=/dev/mapper/vg0-swap`, does **not** contain `nohibernate` |
| swap | `vg0-swap` (~48G) and zram |

If `/` is still the SanDisk mapper: firmware booted the old disk. Stop and send the human back to the UEFI menu.

## 13. Hibernate smoke (human present)

```bash
busctl call org.freedesktop.login1 /org/freedesktop/login1 \
  org.freedesktop.login1.Manager CanHibernate
```

Expect `s "yes"`. Then ask the human before:

```bash
systemctl hibernate
```

On resume: session unlocks, niri/NVIDIA comes back, `journalctl -b -1 -u nvidia-hibernate` is not a stack of errors.

If resume hangs: hard power-off, boot the 1T NVMe again (normal boot, hibernate image discarded). Leave SanDisk installed. Report; do not loop.

**Done:** one successful hibernate+resume **or** a written failure note. Disk migration is still valid without a passing hibernate.

## 14. Close the graph

Update `foam/architecture/nvme-system-migration.md`: status **done**, replace the “current layout” table with vg0 + the new serials. Leave ADR-003 / ADR-004 accepted.

SanDisk wipe (2026-11-25, human GO): identify by serial `1948B0800288` only; destroy LUKS header; `blkdiscard`; `sgdisk --zap-all`; delete NVRAM entries on PARTUUID `da025c61`. Do not touch FOX SPIRIT / HDD / WD_BLACK.

**Done:** foam layout table matches `lsblk`; playbook status can be marked done at the top of this file.

---

## Guardrails (positive)

- Format and `sgdisk` only `$NEW`.
- Keep `/games` and `/hdd` mounted from the existing disks.
- Keep the SanDisk until session 2 **Done** (wiped afterwards, 2026-11-25).
- Copy `/home`, `/nix`, `/var`, `/etc` with rsync (host keys, Tailscale, nix-maid). `nixos-install` does not copy them.
