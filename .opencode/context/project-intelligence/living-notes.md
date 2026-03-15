<!-- Context: project-intelligence/notes | Priority: high | Version: 2.0 | Updated: 2026-03-15 -->

# Living Notes - NixOS Configuration

> Active issues, technical debt, open questions, and insights for this NixOS system configuration.

## Quick Reference

- **Purpose**: Capture current state of NixOS config, problems, and open questions
- **Update**: When adding new modules or encountering issues
- **Archive**: Move resolved items to bottom with resolution date

## Technical Debt

| Item | Impact | Priority | Mitigation |
|------|--------|----------|------------|
| Regular flake.lock updates needed | Security patches may lag behind main branch | Medium | Schedule monthly `nix flake update` |
| niri Wayland compatibility | Some legacy X11 apps may have issues | Low | Use XWayland or find Wayland-native alternatives |

### Technical Debt Details

**Regular flake.lock updates needed**  
*Priority*: Medium  
*Impact*: Security patches and bug fixes in packages may not be available until next update cycle  
*Root Cause*: Flakes lock dependencies for reproducibility, but this means slower adoption of updates  
*Proposed Solution*: Schedule monthly review with `nix flake update` to check for important security updates  
*Effort*: Small (15-30 min per month)  
*Status*: Acknowledged

**niri Wayland compatibility**  
*Priority*: Low  
*Impact*: Some older applications may not work correctly under Wayland, requiring XWayland workaround  
*Root Cause*: Wayland ecosystem still maturing compared to mature X11 setup  
*Proposed Solution*: Document known problematic apps and provide XWayland fallback instructions  
*Effort*: Small (documentation update)  
*Status*: In Progress

## Open Questions

| Question | Stakeholders | Status | Next Action |
|----------|--------------|--------|-------------|
| Should we migrate to nixos-25.05 for LTS stability? | System administrator | Open | Evaluate LTS benefits vs newer packages in 25.11 |
| Is Home Manager worth adopting later for more complex user config? | System administrator | Open | Review when dotfiles grow beyond current scope |

### Open Question Details

**Should we migrate to nixos-25.05 for LTS stability?**  
*Context*: NixOS releases annual LTS versions; currently on nixos-unstable (25.11) channel  
*Stakeholders*: System administrator (chaton)  
*Options*: Stay on unstable for newest packages vs migrate to LTS for stability  
*Timeline*: Evaluate in Q3 2026 after using current setup for 6 months  
*Status*: Open

**Is Home Manager worth adopting later?**  
*Context*: Currently using nix-maid for user-level config; HM provides more comprehensive tooling  
*Stakeholders*: System administrator (chaton)  
*Options*: Continue with nix-maid vs adopt Home Manager  
*Timeline*: Revisit when dotfiles complexity increases beyond current scope  
*Status*: Open

## Known Issues

| Issue | Severity | Workaround | Status |
|-------|----------|------------|--------|
| None at this time | - | - | Clean slate |

### Issue Details

**No active issues**  
*Severity*: N/A  
*Impact*: System running stable with no known blockers  
*Reproduction*: Not applicable  
*Workaround*: Not needed  
*Root Cause*: N/A  
*Fix Plan*: Continue monitoring and document any issues as they arise  
*Status*: Clean slate (as of 2026-03-15)

## Insights & Lessons Learned

### What Works Well
- **Modular structure**: Easy to add new features without breaking existing config - each module is self-contained and testable independently
- **Flake locking**: Builds are reproducible across machines; no unexpected breakages from upstream changes
- **Helix + direnv**: Project-specific LSPs load automatically, excellent Nix support out of the box
- **nix-maid vs Home Manager**: Simpler than expected for personal setup; less complexity to maintain

### What Could Be Better
- **Update cadence**: Need to establish regular schedule for `nix flake update` to stay current with security patches
- **Documentation gaps**: Some custom modules lack detailed comments explaining their purpose
- **Testing automation**: Manual rebuild process could benefit from CI validation for config syntax errors

### Lessons Learned
- **Start simple, expand later**: nix-maid proved sufficient; don't over-engineer early on
- **Modular design pays off**: Adding new features is easier when each module has clear boundaries
- **Document as you go**: Better to add comments during implementation than retroactively
- **Test before applying**: `nixos-rebuild build-vm` saved time by catching errors without breaking production system

## Patterns & Conventions

### Code Patterns Worth Preserving
- **Module structure in configuration.nix**: Clear import order (core → system → desktop → dev → gaming) - easy to find where things belong
- **secrets.nix pattern**: Always import secrets, never commit credentials - security best practice maintained
- **alejandra formatting**: Consistent Nix syntax across all files; run before commits
- **Helix LSP config in dev/helix.nix**: Centralized LSP configuration makes it easy to add new language servers

### Gotchas for Maintainers
- **hardware-configuration.nix is auto-generated**: Never edit manually; always regenerate with `nixos-generate-config`
- **Import order matters in NixOS modules**: Some modules must be loaded before others (e.g., GPU drivers before display manager)
- **secrets.nix must exist on target machine**: Config will fail to evaluate if secrets file is missing
- **Flake inputs need updating**: `nix flake update` required for new package versions; don't rely on automatic updates

## Active Projects

| Project | Goal | Owner | Timeline |
|---------|------|-------|----------|
| Virtual environment templates | Create reusable Nix flakes for project setups | chaton | Ongoing |
| Gaming setup optimization | Improve Steam/Proton performance | chaton | Q2 2026 |

## Archive (Resolved Items)

Moved here for historical reference. Current team should refer to current notes above.

### Resolved: Initial system configuration
- **Resolved**: 2026-03-15
- **Resolution**: Successfully migrated from legacy Nix setup to flake-based configuration with nix-maid
- **Learnings**: Modular structure and clear separation of concerns makes maintenance much easier

## Onboarding Checklist

- [ ] Review known technical debt and understand impact
- [ ] Know what open questions exist and who's involved
- [ ] Understand current issues and workarounds
- [ ] Be aware of patterns and gotchas (especially hardware-configuration.nix never edit manually)
- [ ] Know active projects and timelines
- [ ] Understand the system administrator's priorities

## Related Files

- `decisions-log.md` - Past decisions that inform current state
- `business-domain.md` - Business context for current priorities
- `technical-domain.md` - Technical context for current state
- `business-tech-bridge.md` - Context for current trade-offs
- `AGENTS.md` - Development guidelines and troubleshooting

## Open Questions

| Question | Stakeholders | Status | Next Action |
|----------|--------------|--------|-------------|
| [Question] | [Who needs to decide] | [Open/In Progress] | [What needs to happen] |

### Open Question Details

**[Question]**  
*Context*: [Why this question matters]  
*Stakeholders*: [Who needs to be involved]  
*Options*: [What are the possibilities]  
*Timeline*: [When does this need resolution]  
*Status*: [Open/In Progress/Blocked]

## Known Issues

| Issue | Severity | Workaround | Status |
|-------|----------|------------|--------|
| [Issue] | [Critical/High/Med/Low] | [Temporary fix] | [Known/In Progress/Fixed] |

### Issue Details

**[Issue Title]**  
*Severity*: [Critical/High/Med/Low]  
*Impact*: [Who/what is affected]  
*Reproduction*: [Steps to reproduce if applicable]  
*Workaround*: [Temporary solution if exists]  
*Root Cause*: [If known]  
*Fix Plan*: [How to properly fix]  
*Status*: [Known/In Progress/Fixed in vX.X]

## Insights & Lessons Learned

### What Works Well
- [Positive pattern 1] - [Why it works]
- [Positive pattern 2] - [Why it works]

### What Could Be Better
- [Area for improvement 1] - [Why it's a problem]
- [Area for improvement 2] - [Why it's a problem]

### Lessons Learned
- [Lesson 1] - [Context and implication]
- [Lesson 2] - [Context and implication]

## Patterns & Conventions

### Code Patterns Worth Preserving
- [Pattern 1] - [Where it lives, why it's good]
- [Pattern 2] - [Where it lives, why it's good]

### Gotchas for Maintainers
- [Gotcha 1] - [What to watch out for]
- [Gotcha 2] - [What to watch out for]

## Active Projects

| Project | Goal | Owner | Timeline |
|---------|------|-------|----------|
| [Project] | [What we're doing] | [Who owns it] | [When it matters] |

## Archive (Resolved Items)

Moved here for historical reference. Current team should refer to current notes above.

### Resolved: [Item]
- **Resolved**: [Date]
- **Resolution**: [What was decided/done]
- **Learnings**: [What we learned from this]

## Onboarding Checklist

- [ ] Review known technical debt and understand impact
- [ ] Know what open questions exist and who's involved
- [ ] Understand current issues and workarounds
- [ ] Be aware of patterns and gotchas
- [ ] Know active projects and timelines
- [ ] Understand the team's priorities

## Related Files

- `decisions-log.md` - Past decisions that inform current state
- `business-domain.md` - Business context for current priorities
- `technical-domain.md` - Technical context for current state
- `business-tech-bridge.md` - Context for current trade-offs
