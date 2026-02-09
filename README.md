## My nix configuration

### how to use it : 

To use this NixOS configuration:

1. **Clone this repository:**
   ```sh
   git clone <your-repo-url>
   cd <your-repo>
   ```

2. **Build and switch to the configuration:**
   ```sh
   sudo nixos-rebuild switch --flake .
   ```

3. **Update your config and apply changes:**
   - Edit files as needed (e.g., `configuration.nix`)
   - Reapply with:
     ```sh
     sudo nixos-rebuild switch --flake .
     ```

4. **Upgrade all inputs and update the system:**
   ```sh
   nix flake update
   sudo nixos-rebuild switch --flake .
   ```

**Tip:**  
- Always review changes with `git diff` before rebuilding.
- See [NixOS Manual](https://nixos.org/manual/nixos/stable/) for more information.

### Tests

To test your Nix configuration without applying it, you can run:

```sh
sudo nixos-rebuild test --flake .
```

This will build and test your configuration, but won't make permanent changes or reboot the system. Check the output for possible errors or warnings before proceeding to a full switch.
