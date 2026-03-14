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
└── virtual-envs/              # Virtual environment setups
    ├── templates/             # Some templates to use in dev projects as environment setup
    │   ├── fullstack/         # Full-stack dev environment
    │   └── ...
    ├── certbot/               # Certbot configuration with custom commands
    └── ...
```

### Key Files
- **flake.nix**: Defines Nix inputs and outputs, including system configurations
- **configuration.nix**: Main imports for system configuration
- **hardware-configuration.nix**: Auto-generated hardware settings (do not edit manually)
- **users.nix**: User-specific configurations and package installations

### NixOS Flakes Workflow (No Home Manager, Using nix-maid)

This configuration uses **NixOS with flakes** as the primary workflow, **without Home Manager**. Instead, the setup relies on [nix-maid](https://github.com/viperML/nix-maid) to personalize configuration files and user-specific settings that are not managed by the standard system configuration.

#### Core Workflow

1. **Edit system configuration:**
   - Main system settings are managed in `configuration.nix` and supplementary `.nix` modules inside the `/system/`, `/desktop/`, `/dev/`, etc. directories.
   - Do **not** use or configure `home-manager` modules. Personal dotfiles and user config are not handled by Home Manager here.

2. **Personalization with nix-maid:**
   - User-level dotfiles, non-system configuration files, and user scripts are managed via `nix-maid`.
   - Add `nix-maid` modules or managed files under the appropriate location, typically referenced via `nix-maid.nixosModules.default` in `flake.nix`.
   - To add managed files, use the nix-maid mechanisms (see nix-maid documentation) instead of placing them in Home Manager modules.

3. **Build, Test, and Apply:**
   - Build and check the current configuration:
     ```sh
     nixos-rebuild build --flake .#neo-nix
     ```
   - Switch (apply the configuration):
     ```sh
     sudo nixos-rebuild switch --flake .#neo-nix
     ```
   - You can validate/evaluate your configuration without building:
     ```sh
     nix-instantiate --eval -E 'with import ./.; config'
     ```

4. **Flake Management:**
   - Lock/update flake inputs:
     ```sh
     nix flake update
     ```
   - Add or update system modules in the `flake.nix`'s outputs.

5. **User-Specific Configuration:**
   - All dotfiles and scripts for specific users should be organized within the appropriate nix-maid structure. Update your `flake.nix` to include or reference these as needed.
   - Avoid using Home Manager commands or configuration files.

6. **Consistent Formatting:**
   - Use `alejandra .` to format all Nix files before committing.

#### Summary

- **Flakes-powered** declarative configuration, without Home Manager
- **nix-maid** is used for user-level configuration, dotfiles, and local scripts
- System-wide settings live in traditional NixOS modules
- All configuration and personalization tracked in the flake for reproducibility

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

### AI Tool
- Configured in `dev/ai.nix`
- opencode.json defines model providers and settings
- Models available:
  - Gemma 3n-e4b (local)
  - Mistral Devstral Small 2 2512 (local)
  - Qwen.3 35b A3B (local)
  - GLM 4.7 Flash (local)

### Setting Up a new template for dev Projects or a one-time application
1. Create a new directory under `virtual-envs/` or `virtual-envs/templates/`
2. Add a `flake.nix` with project-specific dependencies
3. Create a `shell.nix` for development environment
4. Add `.envrc` for direnv integration:
   ```bash
   use flake
   ```
5. Commit the new files to version control

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
- [nix-maid documentation](https://github.com/viperML/nix-maid)
- [Alejandra Formatter](https://github.com/kamadorueda/alejandra)
- [Helix Editor](https://helix-editor.com/)
