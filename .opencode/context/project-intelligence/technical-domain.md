<!-- Context: project-intelligence/technical | Priority: critical | Version: 2.0 | Updated: 2026-03-15 -->

# Technical Domain - NixOS Configuration

> Document the technical foundation, architecture, and key decisions for this NixOS declarative configuration.

## Quick Reference

- **Purpose**: Understand how the NixOS system configuration works technically
- **Update When**: Tech stack changes (flake inputs), new modules, workflow changes
- **Audience**: Developers maintaining this NixOS configuration, AI agents generating config code

## Primary Stack

| Layer | Technology | Version | Rationale |
|-------|-----------|---------|----------|
| OS | NixOS | 25.11 (nixos-unstable) | Latest stable with newest packages |
| Config System | Nix Flakes | Current flake.nix | Reproducible, locked dependencies |
| Personalization | nix-maid | viperML/nix-maid | User-level dotfiles without Home Manager |
| Formatter | alejandra | 4.0.0 | Consistent Nix formatting (RFC style) |
| Editor | Helix | Latest | Rust-based, Lua config via direnv |
| Window Manager | niri | Latest | Wayland compositor with dndm support |

## Architecture Pattern

```
Type: Declarative Infrastructure as Code
Pattern: Modular NixOS modules with flakes
Diagram: See project structure below
```

### Why This Architecture?

**Technical reasons:**
- **Reproducibility**: Flakes lock dependencies (`flake.lock`) ensuring builds work months later
- **Modularity**: System config split into focused modules (system/, dev/, desktop/, gaming/)
- **Atomic updates**: `nixos-rebuild switch` creates new generation, rollback on failure
- **Personalization without Home Manager**: nix-maid handles user dotfiles separately from system config

**Alternatives considered:**
- **Home Manager**: Rejected - chose nix-maid for simpler user-level configuration
- **NixOps/Terraform**: Overkill for single-machine desktop setup
- **Imperative scripts**: NixOS provides better reproducibility and rollback

## Project Structure

```
/home/chaton/etc/nixos/
├── flake.nix                      # Core: defines inputs, outputs, system config
├── configuration.nix              # Main imports for all modules
├── hardware-configuration.nix     # Auto-generated: DO NOT EDIT MANUALLY
├── users.nix                      # User-specific packages and settings
┤
├── system/                        # System-level configurations
│   ├── boot.nix                   # Bootloader (GRUB/systemd-boot)
│   ├── locale.nix                 # Locale and timezone settings
│   ├── network.nix                # Network configuration
│   ├── gpu.nix                    # GPU drivers and X11/Wayland setup
│   ├── system.nix                 # Core system packages
│   ├── security.nix               # Security hardening (firewall, sudo)
│   ├── devices.nix                # Bluetooth, input devices
│   └── update-notifier.nix        # System update notifications
├── desktop/                       # Desktop environment configs
│   ├── default.nix                # Fonts, display manager, WM imports
│   └── niri/niri.nix              # niri compositor configuration
├── dev/                           # Development tools and editor config
│   ├── default.nix                # Git, CLI tools, direnv setup
│   ├── helix.nix                  # Helix LSPs and editor settings
│   ├── ai.nix                     # AI tooling (opencode models)
│   └── docker.nix                 # Docker/container support
├── gaming/                        # Gaming-related configurations
│   ├── default.nix                # Steam, Proton, VR support
│   ├── steam.nix                  # Steam client and games
│   └── vr/vr.nix                  # Virtual reality setup
├── apps/                          # User applications
│   ├── browsers.nix               # Web browsers (Zen, Firefox)
│   ├── streaming.nix              # Streaming apps (Spotify, Discord)
│   └── dao.nix                    # DAO/research tools
├── pkgs/                          # Custom Nix packages
│   ├── rtk-ai/default.nix         # Local AI package build
│   └── openwork/default.nix       # Custom tooling
└── virtual-envs/                  # Project dev environments (templates)
    ├── templates/                 # Reusable flake templates
    │   ├── fullstack/             # Full-stack web dev environment
    │   └── ...
    └── certbot/                   # SSL certificate automation
```

**Key Directories:**
- `system/` - Core system configuration, imported in `configuration.nix`
- `desktop/` - GUI components (display manager, fonts, window manager)
- `dev/` - Developer tools, editor config (Helix), AI tooling
- `virtual-envs/` - Reusable Nix flake templates for other projects

## Key Technical Decisions

| Decision | Rationale | Impact |
|----------|-----------|--------|
| **Flakes over legacy Nix** | Reproducibility, locked inputs | Builds work consistently across machines and time |
| **nix-maid instead of Home Manager** | Simpler user-level config, no HM overhead | Easier to manage dotfiles without HM complexity |
| **Modular imports in configuration.nix** | Separation of concerns | Easier maintenance, testing individual modules |
| **Helix + direnv for editor** | Rust-based, fast LSP loading per project | Project-specific tooling (nil for Nix, taplo for TOML) |
| **niri Wayland compositor** | Modern tiling WM with smooth animations | Better GPU utilization than X11 |

## Integration Points

| System | Purpose | Protocol | Direction |
|--------|---------|----------|----------|
| nixpkgs | Package source | Git submodule (flake input) | Outbound (fetch packages) |
| nix-maid | User dotfiles management | Nix module import | Inbound (user config) |
| GitHub | Source for flake inputs | HTTPS/git+https | Outbound (pull dependencies) |

## Technical Constraints

| Constraint | Origin | Impact |
|------------|--------|--------|
| **No Home Manager** | Design decision | User dotfiles managed via nix-maid only |
| **NixOS 25.11 channel** | Stability vs freshness trade-off | Must update flake.lock periodically for security patches |
| **Wayland-only (niri)** | Modern compositor requirement | X11 apps run via XWayland, some legacy tools may have issues |
| **Secrets in secrets.nix** | Security best practice | Never commit secrets; must be present on system |

## Development Environment

```bash
# Setup: Ensure Nix with flakes enabled and direnv installed
# Requirements: nix (with flakes), git, alejandra (optional but recommended)

# Build configuration:
nix build .#nixosConfigurations.neo-nix.config.system.build.toplevel

# Apply configuration:
sudo nixos-rebuild switch --flake .#neo-nix

# Validate without building:
nix-instantiate --eval -E 'with import ./.; config'

# Format Nix files:
alejandra .

# Enter dev shell for a virtual-env project:
cd virtual-envs/templates/python-fastapi && direnv allow
```

**Requirements:**
- Nix with flakes enabled (`experimental-features = nix-command flakes`)
- `direnv` installed and hooked into shell
- `alejandra` formatter (recommended before commits)
- Root/sudo access for applying system config

## Testing & Validation

```bash
# Dry-run rebuild (no changes applied):
sudo nixos-rebuild switch --flake .#neo-nix --dry-live

# Build VM to test safely:
nixos-rebuild build-vm --keep-failed

# List system generations (for rollback):
nix-env -p /nix/var/nix/profiles/system --list-generations

# Rollback to previous generation:
sudo nixos-rebuild switch --generation <N>
```

## Deployment

```nushell
Environment: Desktop workstation (development machine)
Platform: NixOS Linux (native, not VM or cloud)
Build Command: sudo nixos-rebuild switch --flake .#neo-nix
Rollback: sudo nixos-rebuild switch --generation <N>
Monitoring: journalctl -xe for errors, system state version tracking
```

**Deployment workflow:**
1. Edit modules in appropriate directory (system/, dev/, etc.)
2. Validate: `nix-instantiate --eval -E 'with import ./.; config'`
3. Dry-run: `sudo nixos-rebuild switch --flake .#neo-nix --dry-live`
4. Apply: `sudo nixos-rebuild switch --flake .#neo-nix`
5. Verify: Check system state, run tests if applicable

## Onboarding Checklist

- [ ] Understand NixOS basics and flake syntax
- [ ] Know the modular structure (system/, dev/, desktop/)
- [ ] Be able to build and apply configuration changes
- [ ] Understand secrets.nix and never commit it
- [ ] Know how to rollback a broken config
- [ ] Familiar with Helix editor + direnv for LSPs
- [ ] Read AGENTS.md for tooling conventions

## Related Files

- `AGENTS.md` - Complete development guidelines, commands, best practices
- `decisions-log.md` - Major technical decisions with alternatives and context
- `living-notes.md` - Active issues, debt, open questions
- `.opencode/context/project-intelligence/business-domain.md` - Why this config exists (personal workstation)
- `.opencode/context/project-intelligence/business-tech-bridge.md` - Personal needs mapped to NixOS features

## 📂 Codebase References

**Implementation**: `flake.nix`, `configuration.nix` - Core flake definition and imports
**Editor Config**: `dev/helix.nix` - Helix LSP configuration (nil, taplo, yaml-language-server)
**System Modules**: `system/*.nix` - Individual system configuration modules
**Formatter**: alejandra configured via nix-maid for consistent Nix formatting

## Maintenance Guide

**Update flake inputs:**
```bash
nix flake update  # Update all inputs to latest versions
# OR specific input:
nix flake lock --update-input nixpkgs
```

**Add new module:**
1. Create `system/my-feature.nix` with standard NixOS module format
2. Import in `configuration.nix`: `[ ./system/my-feature.nix ]`
3. Test: `nixos-rebuild switch --flake .#neo-nix`

**Remove feature:**
1. Delete or comment out the import from `configuration.nix`
2. Delete module file (or keep for history)
3. Commit and push changes

## Security Notes

- **Secrets**: Store in `secrets.nix` (gitignored), never commit credentials
- **Minimal packages**: Only install what's needed to reduce attack surface
- **Regular updates**: Run `nix flake update` periodically for security patches
- **Firewall**: See `system/security.nix` for default deny rules

## Related Files

- `.opencode/context/core/standards/code-quality.md` - Nix formatting and quality standards
- `.opencode/context/core/workflows/task-delegation-basics.md` - How to delegate config updates
