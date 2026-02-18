# Legacy shell.nix for projects without flakes (use "use nix" in .envrc)
{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs_22
    pnpm
    typescript
    typescript-language-server
    vue-language-server
    vscode-langservers-extracted
    tailwindcss-language-server
    emmet-language-server
  ];

  shellHook = ''
    echo "󰡪 Vue/Nuxt env — node $(node --version) | pnpm $(pnpm --version)"
  '';
}
