{
  pkgs,
  lib,
  ...
}: let
  parakeetAsr = pkgs.parakeet-asr;
in {
  environment.systemPackages = [parakeetAsr];

  systemd.services.parakeet-asr = {
    description = "Parakeet TDT OpenAI-compatible STT (localhost)";
    after = ["network.target" "parakeet-asr-models.service"];
    requires = ["parakeet-asr-models.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      User = "chaton";
      Group = "users";
      ExecStart = "${parakeetAsr}/bin/parakeet -port 10310 -gpu cpu -models /hdd/parakeet";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PARAKEET_GPU=cpu"
        "HOME=/home/chaton"
        "ONNXRUNTIME_LIB=${parakeetAsr}/lib/libonnxruntime.so"
      ];
      WorkingDirectory = "/hdd/parakeet";
      PrivateTmp = true;
      # Upstream parakeet only exposes -port (binds *:port); restrict clients to loopback.
      IPAddressDeny = "any";
      IPAddressAllow = ["localhost" "127.0.0.1" "::1"];
    };
    path = [pkgs.ffmpeg];
  };

  systemd.services.parakeet-asr-models = {
    description = "Download Parakeet ONNX models";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    before = ["parakeet-asr.service"];
    serviceConfig = {
      Type = "oneshot";
      User = "chaton";
      Group = "users";
    };
    script = ''
      mkdir -p /hdd/parakeet
      cd /hdd/parakeet

      # Download Silero VAD
      if [ ! -f "silero_vad.onnx" ]; then
        ${pkgs.curl}/bin/curl -L -o silero_vad.onnx "https://github.com/snakers4/silero-vad/raw/v6.2.1/src/silero_vad/data/silero_vad.onnx"
      fi

      # Download Parakeet TDT int8 models
      for file in config.json vocab.txt nemo128.onnx encoder-model.int8.onnx decoder_joint-model.int8.onnx; do
        if [ ! -f "$file" ]; then
          ${pkgs.curl}/bin/curl -L -o "$file" "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/main/$file"
        fi
      done
    '';
  };
}
