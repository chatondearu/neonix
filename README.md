## My NixOS Configuration

Custom NixOS configuration with Niri (scrollable window manager), integrating nix-maid and various configurations for development, gaming, and streaming.

### 📁 Project Structure

```
/etc/nixos/
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


### 🚀 Usage

#### 1. Initial Installation

```sh
# Clone the repository
git clone <your-repo-url> /etc/nixos
cd /etc/nixos

# Configure secrets
cp secrets.nix.example secrets.nix
# Edit secrets.nix with your values

# Apply the configuration
sudo nixos-rebuild switch --flake .#neo-nix
```

#### 2. Modifications and Updates

```sh
# Edit the configuration
vim configuration.nix  # or any other file

# Test before applying (recommended)
sudo nixos-rebuild test --flake .#neo-nix

# Apply changes
sudo nixos-rebuild switch --flake .#neo-nix
```

#### 3. Updating Inputs

```sh
# Update all inputs (nixpkgs, etc.)
nix flake update

# Or update a specific input
nix flake lock --update-input nixpkgs

# Apply after updating
sudo nixos-rebuild switch --flake .#neo-nix
```

#### 4. Useful Commands

```sh
# Check syntax without building
nix flake check

# View available inputs
nix flake metadata

# Format code with Alejandra
alejandra .

# Show differences before rebuild
git diff

# List previous generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to a previous generation
sudo nixos-rebuild switch --rollback
```

### 🔧 Secrets Configuration

Secrets are stored in the `secrets/` folder and imported via `secrets.nix`. To secure your secrets:

1. Copy the template: `cp secrets.nix.example secrets.nix`
2. Edit `secrets.nix` with your values
3. The file is automatically gitignored

**Note:** Currently, secrets are managed manually. See the TODO section for more robust solutions.

### 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Niri Documentation](https://github.com/YaLTeR/niri)
- [Flakes Wiki](https://nixos.wiki/wiki/Flakes)

### ✨ Features

- **Window Manager:** Niri (scrollable tiling) with custom Waybar configuration
- **Unstable Packages:** Access to latest versions via nixpkgs-unstable
- **Gaming:** Full support including Steam, VR, etc.
- **Development:** Environments for Node.js, Python, and other dev tools
- **Streaming:** OBS configuration and associated tools
- **Formatter:** Alejandra for automatically formatted Nix code

### Niri / Wayland setup notes

- **Base channel:** system base is pinned to `nixos-25.11` through `flake.nix` and `flake.lock`.
- **Targeted unstable composition:** `niri`, `dms-*`, and `steam` are pulled from unstable through `unstable.nix`.
- **Niri module source:** the stable Niri module is disabled and replaced by the unstable module in `desktop/niri/niri.nix` on purpose.
- **XWayland support:** `services.xserver.enable = true` is kept to support legacy X11 apps through XWayland.
- **Session management:** this setup uses `greetd` + `dms-greeter` + `niri` + `dms-shell`; user-level services such as Sunshine should be handled via `systemctl --user`.

### Utils

`sudo rm -f /run/avahi-daemon/pid && sudo systemctl restart avahi-daemon`

### 📝 TODO

- [ ] **Improved secrets management**
  - [ ] Implement [agenix](https://github.com/ryantm/agenix) for secrets encryption with age
  - [ ] Alternative: [sops-nix](https://github.com/Mic92/sops-nix) for SOPS (Secrets OPerationS)
  - [ ] Migrate current secrets to the chosen solution
  - [ ] Document the secrets management workflow

- [ ] **Configuration improvements**
  - [x] Separate configuration into more modular modules
  - [ ] Add automated tests for configurations
  - [ ] Create optional profiles (minimal, desktop, gaming, etc.)
  
- [ ] **Documentation**
  - [ ] Document Niri-specific options
  - [ ] Add configuration screenshots
  - [ ] Create a troubleshooting guide

- [ ] **CI/CD**
  - [ ] Configure GitHub Actions to verify builds
  - [ ] Auto-format with Alejandra in CI

- [x] **Optimizations**
  - [x] Configure binary cache to speed up builds
  - [x] Automatically clean up old generations
