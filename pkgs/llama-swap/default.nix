{
  lib,
  stdenvNoCC,
  fetchurl,
}: let
  sourcesJson = lib.importJSON ./sources.json;
  version = sourcesJson.version;
in
  stdenvNoCC.mkDerivation {
    pname = "llama-swap";
    inherit version;

    src = fetchurl {
      url = "https://github.com/mostlygeek/llama-swap/releases/download/v${version}/llama-swap_${version}_linux_amd64.tar.gz";
      hash = sourcesJson.hash;
    };

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    tar -xzf $src -C $out/bin
    chmod +x $out/bin/llama-swap
      runHook postInstall
    '';

    updateScript = ./update.sh;

    meta = with lib; {
      description = "OpenAI-compatible proxy with automatic llama.cpp model swapping";
      homepage = "https://github.com/mostlygeek/llama-swap";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "llama-swap";
    };
  }
