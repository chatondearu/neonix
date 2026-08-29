{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  pipewire,
  wl-clipboard,
  wtype,
  libnotify,
  bash,
  curl,
  util-linux,
  ffmpeg,
  jq,
}: let
  py = python3.withPackages (ps: [ps.wyoming ps.httpx]);
  pyKeys = python3.withPackages (ps: [ps.evdev]);
in
  stdenvNoCC.mkDerivation {
    pname = "dictation-ptt";
    version = "0.2.0";
    src = ../../scripts/ai/dictation-ptt;
    nativeBuildInputs = [makeWrapper];
    installPhase = ''
      mkdir -p $out/lib/dictation-ptt $out/bin
      cp -r . $out/lib/dictation-ptt/

      makeWrapper ${bash}/bin/bash $out/bin/dictation-ptt \
        --prefix PATH : ${lib.makeBinPath [py pipewire wl-clipboard wtype libnotify curl util-linux ffmpeg jq]} \
        --set DICTATION_BIN $out/bin/dictation-ptt \
        --set DICTATION_TRANSCRIBE $out/lib/dictation-ptt/wyoming_transcribe.py \
        --set DICTATION_OPENAI_TRANSCRIBE $out/lib/dictation-ptt/openai_transcribe.py \
        --set DICTATION_WHISPER_CPP_TRANSCRIBE $out/lib/dictation-ptt/whisper_cpp_transcribe.py \
        --add-flags "$out/lib/dictation-ptt/dictation-ptt.sh"

      makeWrapper ${pyKeys}/bin/python3 $out/bin/dictation-ptt-keys \
        --set DICTATION_BIN $out/bin/dictation-ptt \
        --add-flags "$out/lib/dictation-ptt/dictation_ptt_keys.py"
    '';
    meta = {
      description = "Hold-to-talk dictation with evdev keyboard PTT helper";
      mainProgram = "dictation-ptt";
    };
  }
