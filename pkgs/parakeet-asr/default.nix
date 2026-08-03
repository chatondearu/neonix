{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  sourcesJson = lib.importJSON ./sources.json;
  version = sourcesJson.version;
  parakeetSrc = fetchurl {
    url = sourcesJson.url;
    hash = sourcesJson.hash;
    name = "parakeet-binary";
  };
  onnxruntimeSrc = fetchurl {
    url = "https://github.com/microsoft/onnxruntime/releases/download/v1.25.1/onnxruntime-linux-x64-1.25.1.tgz";
    hash = "sha256-61ZqSc/EnvBkL4CbaTQLW7ZWx8SQW6hzUm0ibywAWBY=";
    name = "onnxruntime.tgz";
  };
in
  stdenv.mkDerivation {
    pname = "parakeet-asr";
    inherit version;

    srcs = [
      parakeetSrc
      onnxruntimeSrc
    ];

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    buildInputs = [
      stdenv.cc.cc.lib
    ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/lib
      
      # Install parakeet
      cp ${parakeetSrc} $out/bin/parakeet
      chmod +x $out/bin/parakeet

      # Install onnxruntime
      tar -xzf ${onnxruntimeSrc} -C $out/lib --strip-components=2 onnxruntime-linux-x64-1.25.1/lib/libonnxruntime.so.1.25.1 onnxruntime-linux-x64-1.25.1/lib/libonnxruntime_providers_shared.so
      ln -s libonnxruntime.so.1.25.1 $out/lib/libonnxruntime.so.1
      ln -s libonnxruntime.so.1.25.1 $out/lib/libonnxruntime.so
      
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
