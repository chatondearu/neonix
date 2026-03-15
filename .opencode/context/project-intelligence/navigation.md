<!-- Context: project-intelligence/nav | Priority: high | Version: 2.0 | Updated: 2026-03-15 -->

# Project Intelligence - NixOS Configuration

> Quick overview of the NixOS declarative configuration structure and how to navigate it.

## Structure

```
/home/chaton/etc/nixos/
├── flake.nix                          # Core: inputs, outputs, system definition
├── configuration.nix                  # Main imports for all modules
├── hardware-configuration.nix         # Auto-generated: DO NOT EDIT
├── users.nix                          # User packages and settings
│
├── .opencode/context/project-intelligence/
│   ├── navigation.md                  # This file - quick overview
│   ├── technical-domain.md            # Tech stack, architecture, decisions
│   ├── business-domain.md             # Why this config exists (personal needs)
│   ├── business-tech-bridge.md        # Personal needs → NixOS features mapping
│   ├── decisions-log.md               # Major decisions with alternatives
│   └── living-notes.md                # Active issues and open questions
│
├── system/                            # System-level configs
│   ├── boot.nix, locale.nix, network.nix, gpu.nix,
│   ├── system.nix, security.nix, devices.nix, update-notifier.nix
├── desktop/                           # Desktop environment (fonts, WM)
│   └── niri/niri.nix                  # Wayland compositor config
├── dev/                               # Development tools and editor
│   ├── default.nix, helix.nix, ai.nix, docker.nix
├── gaming/                            # Gaming setup (Steam, VR)
├── apps/                              # User applications
└── virtual-envs/                      # Dev environment templates
```

## Quick Routes

| What You Need | File | Description |
|---------------|------|-------------|
| Understand the system | `technical-domain.md` | Tech stack, architecture, key decisions |
| Know why this exists | `business-domain.md` | Personal needs and goals |
| See the connection | `business-tech-bridge.md` | How personal needs map to NixOS features |
| Context for decisions | `decisions-log.md` | Why choices were made with alternatives considered |
| Current state | `living-notes.md` | Active issues, debt, open questions |
| All commands & tools | `AGENTS.md` | Build commands, editor config, troubleshooting |

## Usage

**New to this project:**
1. Start with `navigation.md` (this file)
2. Read `technical-domain.md` for architecture understanding
3. Follow onboarding checklist in technical-domain.md
4. Reference `AGENTS.md` for commands and workflows

**Quick reference:**
- System config → `technical-domain.md`
- Development setup → `dev/helix.nix`, `AGENTS.md`
- Editor shortcuts → `AGENTS.md` (Helix keybindings)
- Troubleshooting → `AGENTS.md` section or `living-notes.md`

## Integration

This project intelligence folder is referenced from:
- `.opencode/context/core/standards/project-intelligence.md` (Project Intelligence standards)
- `.opencode/context/core/system/context-guide.md` (Context loading patterns)
- `AGENTS.md` (Development guidelines for this NixOS setup)

See `.opencode/context/core/context-system.md` for the broader context architecture.

## Maintenance

**Keep current:**
- Update when adding new modules or changing workflows
- Document decisions in `decisions-log.md` as they're made
- Review `living-notes.md` regularly for active issues
- Archive resolved items from `decisions-log.md`

**Update Project Intelligence itself:**
```bash
# Edit file directly:
nano .opencode/context/project-intelligence/technical-domain.md

# Format with alejandra (for Nix files):
alejandro .

# Validate before applying:
nix-instantiate --eval -E 'with import ./.; config'
```

**Management Guide:** See `.opencode/context/core/standards/project-intelligence-management.md` for complete lifecycle management including:
- How to update, add, and remove files
- Version tracking (1.0 = new, 1.x = content updates, 2.x = structure changes)
- Frontmatter standards: `<!-- Context: {category}/{function} | Priority: {level} | Version: X.Y | Updated: YYYY-MM-DD -->`
- Quality checklists and anti-patterns
- Governance and ownership

## Key Workflows

**Build configuration:**
```bash
nix build .#nixosConfigurations.neo-nix.config.system.build.toplevel
```

**Apply changes:**
```bash
sudo nixos-rebuild switch --flake .#neo-nix
```

**Rollback if broken:**
```bash
sudo nixos-rebuild switch --generation <N>
```

**Format Nix files:**
```bash
alejandra .
```

## Related Commands

- `/context` - Manage context files (harvest, organize, validate)
- `/add-context` - Update project intelligence patterns
- `nix flake update` - Update dependency versions
- `journalctl -xe` - View system logs for errors
