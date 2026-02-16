## My NixOS Configuration

Custom NixOS configuration with Niri (scrollable window manager), integrating Home Manager and various configurations for development, gaming, and streaming.

### 📁 Project Structure

```
.
├── flake.nix                    # Main Flake configuration
├── configuration.nix            # Main system configuration
├── hardware-configuration.nix   # Hardware configuration (auto-generated)
├── users.nix                    # User management
├── nix.nix                      # Nix configuration (features, garbage collection, etc.)
├── unstable.nix                 # Packages from nixpkgs-unstable
│
├── wm/                          # Window Managers
│   ├── niri/                    # Niri configuration (scrollable tiling WM)
│   └── plasma/                  # KDE Plasma configuration
│
├── system/                      # System-specific configurations
├── gaming/                      # Gaming configuration
│   └── vr/                      # VR support
│
├── virtualenv/                  # Virtual environments
│   └── nodejs/                  # Node.js configuration
│
├── secrets/                     # Secrets (gitignored)
├── secrets.nix                  # Secrets import
├── secrets.nix.example          # Secrets template
│
├── dev.nix                      # Development tools
├── stream.nix                   # Streaming configuration (OBS, etc.)
└── zsh.nix                      # ZSH configuration
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
# Update all inputs (nixpkgs, home-manager, etc.)
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
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Niri Documentation](https://github.com/YaLTeR/niri)
- [Flakes Wiki](https://nixos.wiki/wiki/Flakes)

### ✨ Features

- **Window Manager:** Niri (scrollable tiling) with custom Waybar configuration
- **Home Manager:** Declarative user environment management
- **Unstable Packages:** Access to latest versions via nixpkgs-unstable
- **Gaming:** Full support including Steam, VR, etc.
- **Development:** Environments for Node.js, Python, and other dev tools
- **Streaming:** OBS configuration and associated tools
- **Formatter:** Alejandra for automatically formatted Nix code

### 📝 TODO

- [ ] **Improved secrets management**
  - [ ] Implement [agenix](https://github.com/ryantm/agenix) for secrets encryption with age
  - [ ] Alternative: [sops-nix](https://github.com/Mic92/sops-nix) for SOPS (Secrets OPerationS)
  - [ ] Migrate current secrets to the chosen solution
  - [ ] Document the secrets management workflow

- [ ] **Configuration improvements**
  - [ ] Separate configuration into more modular modules
  - [ ] Add automated tests for configurations
  - [ ] Create optional profiles (minimal, desktop, gaming, etc.)
  
- [ ] **Documentation**
  - [ ] Document Niri-specific options
  - [ ] Add configuration screenshots
  - [ ] Create a troubleshooting guide

- [ ] **CI/CD**
  - [ ] Configure GitHub Actions to verify builds
  - [ ] Auto-format with Alejandra in CI

- [ ] **Optimizations**
  - [ ] Configure binary cache to speed up builds
  - [ ] Automatically clean up old generations
