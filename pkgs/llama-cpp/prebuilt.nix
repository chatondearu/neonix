# CPU-only official binaries (no CUDA). Use nixpkgs-cuda build for llama-server on GPU.
{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  sourcesJson,
}: let
  version = sourcesJson.prebuilt.version;
  asset = "llama-b${version}-bin-ubuntu-x64.tar.gz";
in
  stdenvNoCC.mkDerivation {
    pname = "llama-cpp";
    version = "b${version}";

    src = fetchurl {
      url = "https://github.com/ggml-org/llama.cpp/releases/download/b${version}/${asset}";
      hash = sourcesJson.prebuilt.hash;
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
    ];

    sourceRoot = "llama-b${version}";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/llama-cpp
      cp -R . $out/lib/llama-cpp/

      for bin in llama llama-server llama-cli llama-bench; do
        if [[ -f "$out/lib/llama-cpp/$bin" ]]; then
          makeWrapper "$out/lib/llama-cpp/$bin" "$out/bin/$bin" \
            --prefix LD_LIBRARY_PATH : "$out/lib/llama-cpp"
        fi
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "llama.cpp CPU binaries from upstream releases (b${version})";
      homepage = "https://github.com/ggml-org/llama.cpp";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "llama";
    };
  }
