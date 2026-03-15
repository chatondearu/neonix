<!-- Context: project-intelligence/business | Priority: high | Version: 2.0 | Updated: 2026-03-15 -->

# Business Domain - NixOS Configuration

> Document the personal and professional context for this NixOS system configuration.

## Quick Reference

- **Purpose**: Understand why this NixOS setup exists and what problems it solves
- **Update When**: Personal/workflow needs change, new requirements emerge
- **Audience**: System administrator (chaton), future maintainers

## Project Identity

```
Project Name: NixOS Personal Configuration (neo-nix)
Tagline: Declarative system configuration with flakes and nix-maid
Problem Statement: Need reproducible, maintainable desktop Linux setup
Solution: NixOS flake-based config with modular architecture
```

## Target User

| Attribute | Details |
|-----------|----------|
| Primary User | chaton (system administrator) - Developer/Researcher |
| Use Case | Daily driver desktop for development, research, and gaming |
| Pain Points Solved | System reproducibility, configuration drift, easy rollback |

## Value Proposition

**For the Administrator**:
- **Reproducibility**: Same config works across any machine with NixOS
- **Atomic Updates**: `nixos-rebuild switch` creates generations for instant rollback
- **Declarative**: System state defined as code, no hidden manual changes
- **Modular**: Easy to add features without breaking existing configuration

**For Future Self/Maintainers**:
- Clear project structure with well-documented modules
- All decisions recorded in decisions-log.md with rationale
- Consistent formatting via alejandra ensures readability
- Flake locking prevents unexpected breakages from upstream changes

## Success Metrics

| Metric | Definition | Target | Current |
|--------|------------|--------|---------|
| Rebuild time | Time from config change to applied system | <5 min | ~3-4 min |
| System stability | Days between manual interventions | >90 days | Ongoing tracking |
| Reproducibility | Config works on new machine without issues | 100% success | Verified once |

## Personal Goals (Business Model Equivalent)

```Configuration as Code Philosophy: Treat system setup as reproducible, version-controlled code
Daily Productivity: Minimize friction in development workflow
Security & Stability: Keep system up-to-date with minimal manual intervention
Flexibility: Easy to experiment and rollback if something breaks
```
</parameter>}}</parameter> </arguments>

## Key Stakeholders (Personal)

| Role | Person | Responsibility |
|------|--------|----------------|
| System Administrator | chaton | Full system configuration, maintenance, and updates |

## Roadmap Context

**Current Focus**: Maintain stable NixOS setup with latest packages via nixos-unstable channel
**Next Milestone**: Evaluate LTS migration (nixos-25.05) in Q3 2026 for better stability
**Long-term Vision**: Personal workstation as fully reproducible infrastructure, potentially extend to team deployment

## Constraints & Trade-offs

- **No Home Manager**: Chose nix-maid for simplicity; limits some automation HM provides - *Why*: Simpler personal setup doesn't need HM complexity
- **nixos-unstable channel**: Latest packages but less stable than LTS - *Why*: Prefer newest software over extended support period
- **Single machine focus**: Config optimized for one workstation, not multi-machine orchestration - *Why*: Personal use case doesn't require NixOps/Terraform complexity
- **Wayland-only (niri)**: Some legacy X11 apps need XWayland - *Why*: Modern compositor benefits outweigh compatibility issues

## Onboarding Checklist

- [ ] Understand the problem statement
- [ ] Identify target users and their needs
- [ ] Know the key value proposition
- [ ] Understand success metrics
- [ ] Know who the stakeholders are
- [ ] Understand current business constraints

## Related Files

- `technical-domain.md` - How this business need is solved technically
- `business-tech-bridge.md` - Mapping between business and technical
- `decisions-log.md` - Business decisions with context
