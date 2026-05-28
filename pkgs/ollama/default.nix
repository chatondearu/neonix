{
  lib,
  stdenvNoCC,
  fetchurl,
  zstd,
  makeWrapper,
}: let
  sourcesJson = lib.importJSON ./sources.json;
  version = sourcesJson.version;
in
  stdenvNoCC.mkDerivation {
    pname = "ollama";
    inherit version;

    src = fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tar.zst";
      hash = sourcesJson.hash;
    };

    nativeBuildInputs = [zstd makeWrapper];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
      runHook preInstall

      mkdir -p unpack $out/bin $out/lib/ollama
      zstd -dc "$src" | tar -x -C unpack
    install -Dm755 unpack/bin/ollama $out/bin/.ollama-unwrapped
    cp -R unpack/lib/ollama/. $out/lib/ollama/

    makeWrapper $out/bin/.ollama-unwrapped $out/bin/ollama \
      --prefix LD_LIBRARY_PATH : $out/lib/ollama/cuda_v12:$out/lib/ollama/cuda_v13

      runHook postInstall
    '';

    updateScript = ./update.sh;

    meta = with lib; {
      description = "Run large language models locally (prebuilt release with bundled CUDA libs)";
      homepage = "https://ollama.com";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "ollama";
    };
  }
