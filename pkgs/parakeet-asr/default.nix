{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  onnxruntime,
}: let
  sourcesJson = lib.importJSON ./sources.json;
  version = sourcesJson.version;
  parakeetSrc = fetchurl {
    url = sourcesJson.url;
    hash = sourcesJson.hash;
    name = "parakeet-binary";
  };
in
  stdenv.mkDerivation {
    pname = "parakeet-asr";
    inherit version;

    src = parakeetSrc;

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [
      stdenv.cc.cc.lib
      onnxruntime
    ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/lib

      cp ${parakeetSrc} $out/bin/parakeet
      chmod +x $out/bin/parakeet

      # Copy nixpkgs onnxruntime .so so ONNXRUNTIME_LIB=$out/lib/libonnxruntime.so stays valid.
      cp -a ${onnxruntime}/lib/libonnxruntime.so* $out/lib/
      cp -a ${onnxruntime}/lib/libonnxruntime_providers_shared.so $out/lib/

      runHook postInstall
    '';

    updateScript = ./update.sh;

    meta = with lib; {
      description = "Parakeet TDT OpenAI-compatible STT";
      homepage = "https://github.com/achetronic/parakeet";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      sourceProvenance = with sourceTypes; [binaryNativeCode];
      mainProgram = "parakeet";
    };
  }
