# PC-specific package overrides (prebuilt releases).
# llama-cpp is wired in dev/ai.nix via callPackage to avoid packageOverrides recursion.
{...}: {
  nixpkgs.config.packageOverrides = pkgs: {
    llama-swap = pkgs.callPackage ./llama-swap/default.nix {};
    parakeet-asr = pkgs.callPackage ./parakeet-asr/default.nix {};
    ollama = pkgs.callPackage ./ollama/default.nix {};
  };
}
