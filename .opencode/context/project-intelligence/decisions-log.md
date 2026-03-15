<!-- Context: project-intelligence/decisions | Priority: high | Version: 2.0 | Updated: 2026-03-15 -->

# Decisions Log - NixOS Configuration

> Record major architectural decisions for this NixOS system configuration with full context.

## Quick Reference

- **Purpose**: Document why NixOS config choices were made (prevents "why was this done?" debates)
- **Format**: Each decision as a separate entry with alternatives considered
- **Status**: Decided | Pending | Under Review | Deprecated

## Decision Template

```markdown
## [Decision Title]

**Date**: YYYY-MM-DD
**Status**: [Decided/Pending/Under Review/Deprecated]
**Owner**: [Who owns this decision]

### Context
[What situation prompted this decision? What was the problem or opportunity?]

### Decision
[What was decided? Be specific about the choice made.]

### Rationale
[Why this decision? What were the alternatives and why were they rejected?]

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| [Alt 1] | [Pros] | [Cons] | [Why not chosen] |
| [Alt 2] | [Pros] | [Cons] | [Why not chosen] |

### Impact
**Positive**: [What this enables or improves]
**Negative**: [What trade-offs or limitations this creates]
**Risk**: [What could go wrong]

### Related
- [Links to related decisions, PRs, issues, or documentation]
```

---

## Decision: Use nix-maid Instead of Home Manager

**Date**: 2026-03-15
**Status**: Decided
**Owner**: chaton (system administrator)

### Context
Needed a way to manage user-level dotfiles and personal configurations without the complexity of full Home Manager integration.

### Decision
Use **nix-maid** for user-level configuration management instead of Home Manager.

### Rationale
Chose nix-maid over Home Manager for this NixOS setup due to:
- Simpler setup: no separate HM configuration needed
- Direct control: user files managed via simple module imports
- Less overhead: HM adds abstraction layers not needed for personal use
- Easier debugging: straightforward Nix expressions vs HM's complex modules

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| Home Manager | Mature, well-documented, large community | Overkill for single-user setup, adds complexity | Chose simpler nix-maid approach |
| Manual symlink scripts | Full control, no dependencies | Error-prone, not declarative, hard to maintain | NixOS's declarative philosophy requires better solution |
| nixos-homefiles | Simpler alternative to HM | Less community support than HM | nix-maid provides better integration with flake-based workflow |

### Impact
- **Positive**: Simpler configuration structure, easier to understand for new maintainers
- **Negative**: Less automation than Home Manager's comprehensive module system
- **Risk**: Must manage user dotfiles manually via nix-maid modules

### Related
- [nix-maid documentation](https://github.com/viperML/nix-maid)
- `flake.nix`: Module import for nix-maid (`nix-maid.nixosModules.default`)
- AGENTS.md: Editor and development tooling configuration

---

## Decision: Flake-Based Configuration with Locked Inputs

**Date**: 2026-03-15
**Status**: Decided
**Owner**: chaton (system administrator)

### Context
Need reproducible builds that work consistently across time and machines.

### Decision
Use **Nix Flakes** for all configuration management with locked inputs in `flake.lock`.

### Rationale
Flakes provide:
- **Reproducibility**: Locked dependency versions ensure builds work months later
- **Portability**: Same config works on any machine with flakes enabled
- **Isolation**: Dependencies pinned, no unexpected updates breaking things
- **Modern Nix**: Officially supported by NixOS for declarative configs

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| Legacy Nix (non-flakes) | Simpler syntax, no experimental feature needed | No built-in locking, less reproducible | Flakes provide better reproducibility guarantees |
| Imperative scripts | Flexible, familiar to some users | Not declarative, hard to reproduce, no rollback | NixOS's core value is declarative config with atomic updates |

### Impact
- **Positive**: Builds are reproducible across time and machines
- **Negative**: Must use `nix flake update` to get new package versions
- **Risk**: Flake experiments still evolving (though now stable in production)

### Related
- [Nix Flakes documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
- `flake.nix`: Core flake definition with inputs and outputs
- AGENTS.md: Commands for updating flakes (`nix flake update`)

---

## Decision: Modular System Configuration Structure

**Date**: 2026-03-15
**Status**: Decided
**Owner**: chaton (system administrator)

### Context
Configuration was growing large and needed better organization for maintainability.

### Decision
Split system configuration into focused modules: `system/`, `dev/`, `desktop/`, `gaming/`, `apps/`.

### Rationale
Modular structure provides:
- **Separation of concerns**: Each module handles one domain (boot, networking, etc.)
- **Easier maintenance**: Changes to one area don't risk breaking others
- **Reusability**: Modules can be imported into other configs if needed
- **Testing**: Can validate individual modules before full rebuild

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| Single configuration.nix file | Simpler, fewer files to manage | Hard to maintain as config grows, merge conflicts likely | Modular approach scales better for complex configs |
| Random directory structure | Flexible organization | Inconsistent patterns make it hard to find things | Clear separation (system/, dev/, desktop/) improves discoverability |

### Impact
- **Positive**: Easier to add new features without touching unrelated code
- **Negative**: Slightly more files to manage, need to remember where things go
- **Risk**: Module dependencies must be carefully managed (import order matters)

### Related
- `configuration.nix`: Main import file showing module structure
- AGENTS.md: Directory layout documentation
- `.opencode/context/project-intelligence/technical-domain.md`: Full project structure

---

## Decision: Helix Editor with direnv for LSPs

**Date**: 2026-03-15
**Status**: Decided
**Owner**: chaton (system administrator)

### Context
Need a modern, fast editor with good Nix support and project-specific tooling.

### Decision
Use **Helix** editor configured via `dev/helix.nix` with direnv for per-project LSP loading.

### Rationale
Chose Helix over Vim/Neovim for:
- **Modern Rust-based**: Fast, safe, good performance
- **Built-in LSP**: No complex plugin management needed
- **Lua config via direnv**: Project-specific tooling loaded automatically
- **Catppuccin theme**: Pleasant visual experience

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| Neovim with LSP plugin | Extremely flexible, huge ecosystem | Complex setup, plugin conflicts common | Helix's minimal setup is better for this workflow |
| VS Code/Nvim | Good IDE features, familiar UI | Heavier resource usage, slower startup | Helix faster and lighter weight |

### Impact
- **Positive**: Fast editor with excellent Nix/LSP support out of the box
- **Negative**: Vim keybindings require configuration (Lua config in helix.nix)
- **Risk**: Helix still maturing, some plugins unavailable vs Vim ecosystem

### Related
- `dev/helix.nix`: LSP and editor configuration
- AGENTS.md: Editor settings and keybindings
- direnv: Project-specific tooling loading

---

## Decision: niri Wayland Compositor

**Date**: 2026-03-15
**Status**: Decided
**Owner**: chaton (system administrator)

### Context
Need a modern tiling window manager with smooth animations and good GPU utilization.

### Decision
Use **niri** as the Wayland compositor instead of traditional X11 setup.

### Rationale
Chose niri for:
- **Modern Wayland**: Better security, smoother rendering than X11
- **Tiling WM**: Efficient keyboard-driven workflow
- **Smooth animations**: GPU-accelerated compositor effects
- **dndm support**: Custom shell integration via DankMaterialShell

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| Sway (X11) | Mature, large community, stable | X11 architecture older, less secure than Wayland | Chose modern Wayland for better GPU utilization |
| Hyprland | Popular, highly customizable | More complex config, occasional stability issues | niri's simpler design is easier to maintain |

### Impact
- **Positive**: Modern compositor with smooth animations and good performance
- **Negative**: Some legacy X11 apps need XWayland (minor compatibility issues)
- **Risk**: Wayland ecosystem still evolving, some apps may have issues

### Related
- `desktop/niri/niri.nix`: Window manager configuration
- AGENTS.md: Desktop environment setup documentation
- [niri GitHub](https://github.com/pystray/niri) (or actual repo)

---

## Deprecated Decisions

Decisions that were later overturned (for historical context):

| Decision | Date | Replaced By | Why |
|----------|------|-------------|-----|
| [Any future deprecation] | [Date] | [New decision] | [Reason for change] |

## Onboarding Checklist

- [ ] Understand the philosophy behind major architectural choices
- [ ] Know why certain technologies were chosen over alternatives
- [ ] Understand trade-offs that were made (nix-maid vs HM, flake locking, modular structure)
- [ ] Know where to find decision context when questions arise
- [ ] Understand what decisions are pending and why

## Related Files

- `technical-domain.md` - Technical implementation affected by these decisions
- `business-tech-bridge.md` - How decisions connect personal needs to NixOS features
- `living-notes.md` - Current open questions that may become future decisions
</parameter> }

**Date**: YYYY-MM-DD
**Status**: [Status]
**Owner**: [Owner]

### Context
[What was happening? Why did we need to decide?]

### Decision
[What we decided]

### Rationale
[Why this was the right choice]

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| [Option A] | [Good things] | [Bad things] | [Reason] |
| [Option B] | [Good things] | [Bad things] | [Reason] |

### Impact
- **Positive**: [What we gain]
- **Negative**: [What we trade off]
- **Risk**: [What to watch for]

### Related
- [Link to PR #000]
- [Link to issue #000]
- [Link to documentation]

---

## Decision: [Title]

**Date**: YYYY-MM-DD
**Status**: [Status]
**Owner**: [Owner]

### Context
[What was happening?]

### Decision
[What we decided]

### Rationale
[Why this was right]

### Alternatives Considered
| Alternative | Pros | Cons | Why Rejected? |
|-------------|------|------|---------------|
| [Option A] | [Good things] | [Bad things] | [Reason] |

### Impact
- **Positive**: [What we gain]
- **Negative**: [What we trade off]

### Related
- [Link]

---

## Deprecated Decisions

Decisions that were later overturned (for historical context):

| Decision | Date | Replaced By | Why |
|----------|------|-------------|-----|
| [Old decision] | [Date] | [New decision] | [Reason] |

## Onboarding Checklist

- [ ] Understand the philosophy behind major architectural choices
- [ ] Know why certain technologies were chosen over alternatives
- [ ] Understand trade-offs that were made
- [ ] Know where to find decision context when questions arise
- [ ] Understand what decisions are pending and why

## Related Files

- `technical-domain.md` - Technical implementation affected by these decisions
- `business-tech-bridge.md` - How decisions connect business and technical
- `living-notes.md` - Current open questions that may become decisions
