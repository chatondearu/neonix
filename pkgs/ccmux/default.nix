{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  sourcesJson = lib.importJSON ./sources.json;
  version = sourcesJson.version;
in
  stdenvNoCC.mkDerivation {
    pname = "ccmux";
    inherit version;

    src = fetchurl {
      url = "https://github.com/skzv/ccmux/releases/download/v${version}/ccmux_linux_amd64.tar.gz";
      hash = sourcesJson.hash;
    };

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      tar -xzf $src -C $out/bin
      chmod +x $out/bin/ccmux $out/bin/ccmuxd $out/bin/ccmux-mcp
      runHook postInstall
    '';

    meta = with lib; {
      description = "TUI to jump between AI agent sessions in tmux";
      homepage = "https://ccmux.dev/";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "ccmux";
    };
  }
