<!-- Context: project-intelligence/bridge | Priority: high | Version: 2.0 | Updated: 2026-03-15 -->

# Business ↔ Tech Bridge - NixOS Configuration

> Document how personal needs translate to technical solutions in this NixOS setup.

## Quick Reference

- **Purpose**: Show how NixOS technical choices serve personal productivity and stability goals
- **Purpose**: Show developers why certain architectural decisions were made
- **Update When**: New features added, workflow changes, tech stack updates

## Core Mapping

| Personal Need | Technical Solution | Why This Mapping | Value Delivered |
|---------------|-------------------|------------------|----------------|
| **Reproducible system setup** | Nix Flakes with locked inputs (`flake.lock`) | Guarantees same config works across time and machines | Can rebuild workstation from scratch anytime without manual steps |
| **Easy rollback on breakage** | NixOS generations via `nixos-rebuild switch` | Each rebuild creates new generation in /run/current-system/generations | Instant recovery: `sudo nixos-rebuild switch --generation <N>` |
| **Modern desktop experience** | niri Wayland compositor with catppuccin theme | Modern GPU-accelerated WM with smooth animations | Better performance and visual experience than X11 |
| **Fast development workflow** | Helix + direnv for project-specific LSPs | Automatic tooling loading per project, no plugin management | Immediate feedback when switching projects, excellent Nix support |
| **System security & updates** | nixos-unstable channel with monthly `nix flake update` | Latest packages with scheduled review cycle | Security patches delivered quickly while maintaining control |
| **User dotfiles managed** | nix-maid module system instead of Home Manager | Direct Nix imports, no HM complexity | Simpler to understand and maintain for personal setup |
| **Gaming capability** | Separate gaming/ modules (Steam, Proton, VR) | Isolated from core system config | Can experiment with games without risking system stability |

## Feature Mapping Examples

### Feature: Modular System Architecture

**Business Context**:
- User need: Easy to maintain and extend personal workstation configuration
- Business goal: Minimize time spent debugging config issues, maximize productivity
- Priority: High - config complexity grows over time

**Technical Implementation**:
- Solution: Split into focused modules (system/, dev/, desktop/, gaming/)
- Architecture: Each module self-contained, imported in `configuration.nix`
- Trade-offs: More files vs single monolithic file - chose modularity for maintainability

**Connection**:
Modular structure directly serves the goal of easy maintenance. When adding a new package or feature, I know exactly which module to edit (e.g., new dev tool → `dev/default.nix`). This reduces cognitive load and prevents "where does this go?" moments.

### Feature: Flake-Based Configuration with Locked Inputs

**Business Context**:
- User need: System works the same way today as it will in 6 months
- Business goal: Avoid configuration drift and unexpected breakages from upstream changes
- Priority: High - reproducibility is core value proposition of NixOS

**Technical Implementation**:
- Solution: `flake.nix` with pinned inputs, committed `flake.lock`
- Architecture: All dependencies (nixpkgs, Home Manager, etc.) locked to specific commits
- Trade-offs: Must run `nix flake update` manually for new versions vs automatic updates

**Connection**:
The lock file ensures that when I rebuild my system or clone this config to a new machine, I get the exact same package versions. This eliminates "it worked yesterday" debugging sessions caused by upstream changes.

### Feature: Helix Editor with direnv LSP Management

**Business Context**:
- User need: Fast editor that understands Nix syntax and provides autocomplete
- Business goal: Reduce friction during config editing, catch errors before applying
- Priority: Medium - improves daily workflow efficiency

**Technical Implementation**:
- Solution: Helix configured via `dev/helix.nix` with nil LSP for Nix, taplo for TOML
- Architecture: direnv loads project-specific LSPs automatically on directory change
- Trade-offs: Helix less popular than VS Code/Vim but excellent Rust-based performance

**Connection**:
Having proper LSP support means I get syntax highlighting and error detection while editing Nix files. This catches mistakes before `nixos-rebuild switch`, saving hours of debugging broken configs.

### Feature: niri Wayland Compositor over X11

**Business Context**:
- User need: Modern, responsive desktop with smooth animations and good GPU utilization
- Business goal: Better visual experience without sacrificing performance
- Priority: Medium - quality-of-life improvement

**Technical Implementation**:
- Solution: niri Wayland compositor with custom dndm shell integration
- Architecture: All GUI apps run under Wayland protocol, X11 apps via XWayland compatibility layer
- Trade-offs: Some legacy applications may have minor issues vs mature X11 ecosystem

**Connection**:
The modern Wayland approach provides smoother animations and better multi-monitor support than traditional X11 setup. For a personal workstation where visual experience matters for long coding sessions, this trade-off is worth it.

## Trade-off Decisions

When personal needs and technical constraints conflict, document the decision:

| Situation | Personal Priority | Technical Constraint | Decision Made | Rationale |
|-----------|-------------------|---------------------|---------------|----------|
| **Package freshness vs stability** | Latest software features | nixos-unstable less stable than LTS | Stay on unstable, update monthly | Prefer newest packages; security patches via regular updates |
| **Simplicity vs automation** | Easy to understand config | Home Manager provides more automation | Chose nix-maid over HM | Simpler setup doesn't need HM complexity; can migrate later if needed |
| **Wayland compatibility** | Modern compositor features | Some apps don't work perfectly on Wayland | Use niri with XWayland fallback | Benefits outweigh minor compatibility issues; most critical apps have native support |

## Common Misalignments

| Misalignment | Warning Signs | Resolution Approach |
|--------------|---------------|---------------------|
| **Over-engineering** | Adding features not immediately needed | Stick to KISS principle; just-in-time feature addition |
| **Update procrastination** | Flake.lock becomes stale, security concerns | Schedule monthly `nix flake update` review |
| **Module sprawl** | Too many small modules, hard to find config | Consolidate related modules; keep focused scope per file |

## Stakeholder Communication (Personal Reflection)

This file helps clarify why technical choices serve personal goals:

**For the Administrator **(Self - Future Me)
- Shows that NixOS investments serve productivity and stability goals
- Provides context for why flake locking requires manual updates
- Demonstrates ROI of modular architecture when debugging issues

**For Documentation/AI Agents**:
- Provides business context for architectural decisions (nix-maid vs HM, niri over Sway)
- Shows the "why" behind constraints and requirements
- Helps prioritize technical debt with personal impact

## Onboarding Checklist

- [ ] Understand how each NixOS feature serves a personal goal
- [ ] See why flake locking is necessary for reproducibility
- [ ] Know the key trade-offs (nix-maid vs HM, Wayland compatibility)
- [ ] Be able to explain to future self why certain choices were made
- [ ] Understand how technical decisions impact daily workflow

## Related Files

- `business-domain.md` - Personal needs and goals in detail
- `technical-domain.md` - Technical implementation in detail
- `decisions-log.md` - Decisions made with full context and alternatives
- `living-notes.md` - Current open questions and issues
- `AGENTS.md` - Development guidelines for maintaining this config

## Feature Mapping Examples

### Feature: [Feature Name]

**Business Context**:
- User need: [What users need]
- Business goal: [Why this matters to business]
- Priority: [Why this was prioritized]

**Technical Implementation**:
- Solution: [What was built]
- Architecture: [How it fits the system]
- Trade-offs: [What was considered and why it won]

**Connection**:
[Explain clearly how the technical solution serves the business need. What would happen without this feature? What does this feature enable for the business?]

### Feature: [Feature Name]

**Business Context**:
- User need: [What users need]
- Business goal: [Why this matters to business]
- Priority: [Why this was prioritized]

**Technical Implementation**:
- Solution: [What was built]
- Architecture: [How it fits the system]
- Trade-offs: [What was considered and why it won]

**Connection**:
[Explain clearly how the technical solution serves the business need.]

## Trade-off Decisions

When business and technical needs conflict, document the trade-off:

| Situation | Business Priority | Technical Priority | Decision Made | Rationale |
|-----------|-------------------|-------------------|---------------|-----------|
| [Conflict] | [What business wants] | [What tech wants] | [What was chosen] | [Why this was right] |

## Common Misalignments

| Misalignment | Warning Signs | Resolution Approach |
|--------------|---------------|---------------------|
| [Type of mismatch] | [Symptoms to watch for] | [How to address] |

## Stakeholder Communication

This file helps translate between worlds:

**For Business Stakeholders**:
- Shows that technical investments serve business goals
- Provides context for why certain choices were made
- Demonstrates ROI of technical decisions

**For Technical Stakeholders**:
- Provides business context for architectural decisions
- Shows the "why" behind constraints and requirements
- Helps prioritize technical debt with business impact

## Onboarding Checklist

- [ ] Understand the core business needs this project addresses
- [ ] See how each major feature maps to business value
- [ ] Know the key trade-offs and why decisions were made
- [ ] Be able to explain to stakeholders why technical choices matter
- [ ] Be able to explain to developers why business constraints exist

## Related Files

- `business-domain.md` - Business needs in detail
- `technical-domain.md` - Technical implementation in detail
- `decisions-log.md` - Decisions made with full context
- `living-notes.md` - Current open questions and issues
