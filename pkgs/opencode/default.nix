{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  makeBinaryWrapper,
  ripgrep,
}: let
  sourcesJson = lib.importJSON ./sources.json;
in
  stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "opencode";
    version = sourcesJson.version;

    # Official Linux CLI binary from GitHub releases.
    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${finalAttrs.version}/opencode-linux-x64.tar.gz";
      hash = sourcesJson.hash;
    };

    nativeBuildInputs = [
      installShellFiles
      makeBinaryWrapper
    ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      tar -xzf $src -C $out/bin
      chmod +x $out/bin/opencode

      # Prebuilt ELF: use makeBinaryWrapper (wrapProgram breaks native binaries).
      mv $out/bin/opencode $out/bin/.opencode-unwrapped
      makeBinaryWrapper $out/bin/.opencode-unwrapped $out/bin/opencode \
        --prefix PATH : ${lib.makeBinPath [ripgrep]}

      runHook postInstall
    '';

    postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
      if $out/bin/opencode completion --help >/dev/null 2>&1; then
        installShellCompletion --cmd opencode \
          --bash <($out/bin/opencode completion) \
          --zsh <(SHELL=/bin/zsh $out/bin/opencode completion)
      fi
    '';

    updateScript = ./update.sh;

    meta = with lib; {
      description = "AI coding agent built for the terminal";
      homepage = "https://github.com/anomalyco/opencode";
      license = licenses.mit;
      maintainers = with maintainers; [chatondearu];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      platforms = ["x86_64-linux"];
      mainProgram = "opencode";
    };
  })
