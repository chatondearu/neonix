# AGENTS.md

This file provides guidelines for agentic coding tools (like opencode) working in this repository.

## Build, Lint, and Test Commands

### NixOS Configuration
- **Build system configuration**: `nix build`
- **Apply configuration**: `sudo nixos-rebuild switch --flake .#neo-nix`
- **Check for configuration errors**: `nix-instantiate --eval -E 'with import ./.; config'`
- **Format Nix files**: `alejandra` (installed as system package)

### Development Tools
- **Enter development shell**: Use direnv with `.envrc` files in project directories
- **List installed packages**: `nix-env -p /nix/var/nix/profiles/system --list-generations`

## Code Style Guidelines

### Nix Language Conventions
- **Formatting**: Use `alejandra` for consistent formatting
- **Imports**: Prefer absolute paths over relative paths in imports
- **Attribute Sets**: Use concise syntax, avoid unnecessary newlines
- **Comments**: Use `#` for comments, keep them concise and relevant

### Editor Configuration (Helix)
- **Theme**: `catppuccin_mocha`
- **Line numbers**: Relative line numbers enabled
- **Mouse support**: Enabled
- **Rulers**: Set at 80 and 120 characters
- **Soft wrap**: Enabled for better readability

### Language-Specific Settings

#### TypeScript/JavaScript
- **Formatter**: `prettierd`
- **Linter**: ESLint with flat config enabled
- **Language servers**: TypeScript, ESLint, TailwindCSS (for TSX/JSX)
- **Auto-format**: Enabled on save

#### Vue
- **Language servers**: Vue LS, TailwindCSS, ESLint
- **Formatter**: `prettierd`
- **Auto-format**: Enabled on save

#### HTML/CSS
- **Language servers**: VSCode HTML LS, TailwindCSS, Emmet (HTML)
- **Formatter**: `prettierd`
- **Auto-format**: Enabled on save

#### Nix
- **Formatter**: `nixfmt-rfc-style`
- **Auto-format**: Enabled on save

#### Rust
- **Auto-format**: Enabled (uses rustfmt)

#### TOML/Markdown/YAML
- **Formatters**: `taplo`, `marksman`, `yaml-language-server` respectively
- **Auto-format**: Enabled where applicable

## Project Structure

### Directory Layout
```
/home/chaton/etc/nixos/
├── configuration.nix          # Main NixOS configuration
├── flake.nix                  # Flake definition with inputs
├── hardware-configuration.nix  # Hardware-specific settings
├── users.nix                  # User configurations
├── system/                    # System-level configurations
│   ├── boot.nix               # Bootloader settings
│   ├── locale.nix             # Locale configuration
│   └── ...
├── desktop/                   # Desktop environment configs
├── dev/                       # Development tools and settings
│   ├── helix.nix              # Helix editor config
│   ├── ai.nix                 # AI tooling setup
│   └── ...
├── gaming/                    # Gaming-related configurations
└── virtualenv/                # Virtual environment setups
    ├── certbot/               # Certbot configuration
    ├── fullstack/             # Full-stack dev environment
    └── ...
```

### Key Files
- **flake.nix**: Defines Nix inputs and outputs, including system configurations
- **configuration.nix**: Main imports for system configuration
- **hardware-configuration.nix**: Auto-generated hardware settings (do not edit manually)
- **users.nix**: User-specific configurations and package installations

## Development Workflow

### Setting Up a New Project
1. Create a new directory under `virtualenv/`
2. Add a `flake.nix` with project-specific dependencies
3. Create a `shell.nix` for development environment
4. Add `.envrc` for direnv integration:
   ```bash
   use flake
   ```
5. Commit the new files to version control

### Adding Dependencies
- For system-wide packages: Add to `environment.systemPackages` in configuration.nix
- For project-specific packages: Add to the project's flake.nix
- Use Nixpkgs inputs from the flake for consistency

### Configuration Management
- Use separate `.nix` files for logical groupings (e.g., `desktop/niri.nix`)
- Import configurations using `imports` in parent files
- Keep configurations modular and reusable

## Best Practices

### NixOS-Specific
1. **Immutable infrastructure**: Treat system configuration as code
2. **Atomic updates**: Use `nixos-rebuild switch` for atomic system changes
3. **Backup flakes**: Regularly commit flake.lock to ensure reproducible builds
4. **Test configurations**: Use `nix-instantiate --eval` to validate before applying

### Code Quality
1. **Consistent formatting**: Always run formatters before committing
2. **Type safety**: Leverage Nix's type system for configuration validation
3. **Documentation**: Add comments for complex or non-obvious configurations
4. **Modularity**: Break down large configurations into smaller, focused files

### Security
1. **Secrets management**: Use `secrets.nix` for sensitive data (never commit secrets)
2. **Minimal privileges**: Follow principle of least privilege in user configurations
3. **Regular updates**: Keep Nixpkgs inputs updated for security patches
4. **Audit changes**: Review all configuration changes before applying to system

## Tooling Integration

### Helix Editor
- Configured via `helix.nix` with global settings
- Project-specific LSPs loaded through direnv
- Keybindings:
  - `C-g`: Save all, run lazygit, reload files
  - `space e`: Open file with yazi file manager

### Git Configuration
- User name and email set via secrets.nix
- Default branch: `main`
- Integrated with gh CLI for GitHub operations

### AI Tools
- Configured in `dev/ai.nix`
- opencode.json defines model providers and settings
- Models available:
  - Gemma 3n-e4b (local)
  - Mistral Devstral Small 2 2512 (local)
  - Qwen.3 35b A3B (local)
  - GLM 4.7 Flash (local)

## Troubleshooting

### Common Issues
- **Configuration errors**: Run `nix-instantiate --eval` to catch issues early
- **Missing dependencies**: Check flake inputs and system packages
- **Formatting problems**: Ensure alejandra/nixfmt are in PATH
- **LSP not activating**: Verify binary exists in PATH for the language server

### Debugging Commands
- `nixos-rebuild build-vm --keep-failed`: Build in a VM to test changes safely
- `nix flake metadata`: Check flake inputs and dependencies
- `nix store gc --print-dead`: Identify unused store paths (cleanup)
- `journalctl -xe`: View system logs for errors

## References
- [NixOS Manual](https://nixos.org/manual/)
- [Home Manager Documentation](https://nix-community.github.io/home-manager/)
- [Alejandra Formatter](https://github.com/kamadorueda/alejandra)
- [Helix Editor](https://helix-editor.com/)
