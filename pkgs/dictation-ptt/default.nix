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
}: let
  py = python3.withPackages (ps: [ps.wyoming ps.httpx]);
in
  stdenvNoCC.mkDerivation {
    pname = "dictation-ptt";
    version = "0.1.0";
    src = ../../scripts/ai/dictation-ptt;
    nativeBuildInputs = [makeWrapper];
    installPhase = ''
      mkdir -p $out/lib/dictation-ptt $out/bin
      cp -r . $out/lib/dictation-ptt/
      makeWrapper ${bash}/bin/bash $out/bin/dictation-ptt \
        --prefix PATH : ${lib.makeBinPath [py pipewire wl-clipboard wtype libnotify curl]} \
        --set DICTATION_TRANSCRIBE $out/lib/dictation-ptt/wyoming_transcribe.py \
        --set DICTATION_OPENAI_TRANSCRIBE $out/lib/dictation-ptt/openai_transcribe.py \
        --add-flags "$out/lib/dictation-ptt/dictation-ptt.sh"
    '';
    meta = {
      description = "Hold-to-talk dictation via Wyoming faster-whisper";
      mainProgram = "dictation-ptt";
    };
  }
