# Test Matrix - Niri / Wayland / Gaming / VR

Use this matrix after significant updates (Nixpkgs, Niri, DMS, Quickshell, GPU stack).

## Core session checks

| Area | Check | Command/Method | Expected |
|------|-------|----------------|----------|
| Login | Greetd flow | Login from greeter | Session opens without crash loop |
| Session type | Wayland active | `echo $XDG_SESSION_TYPE` | `wayland` |
| Desktop id | Niri active | `echo $XDG_CURRENT_DESKTOP` | `niri` |
| Shell | DMS service | `systemctl --user status dms` | active |

## Portal and desktop integration

| Area | Check | Command/Method | Expected |
|------|-------|----------------|----------|
| Portal daemon | xdg-desktop-portal | `systemctl --user status xdg-desktop-portal` | active |
| File chooser | GTK portal path | Trigger file picker from a GUI app | Picker opens and returns selected file |
| Screenshot | Portal screenshot | Use app screenshot request | Screenshot flow completes |
| Screen share | Portal screencast | Share screen in browser/chat app | Stream starts successfully |

## Gaming and streaming

| Area | Check | Command/Method | Expected |
|------|-------|----------------|----------|
| Steam startup | Steam launch | `steam` | Client launches |
| Wayland app | Native app sanity | Run one Wayland-native app | Stable rendering |
| XWayland app | Legacy path sanity | Run one X11/XWayland app | App launches correctly |
| Sunshine | User service state | `systemctl --user status sunshine` | active (if enabled) |
| Gamescope | Basic run | `gamescope -- vkcube` | Starts without immediate crash |

## VR path (when relevant)

| Area | Check | Command/Method | Expected |
|------|-------|----------------|----------|
| WiVRn | Service status | `systemctl --user status wivrn` | active/running |
| SteamVR | Runtime launch | Start SteamVR | Runtime initializes |
| Tracking | Headset/controllers | In-headset validation | Devices tracked normally |

## Recommended execution

1. Run `bash /home/chaton/etc/nixos/gaming/smoke-tests-wayland.sh`.
2. Execute this matrix for changed areas only (full matrix for major updates).
3. Record outcomes in `doc/release-notes/`.
