{ pkgs, ... }:

{
  services.ollama = {
    enable = true;

    # Use the CUDA package for better performance on NVIDIA GPUs
    # will add nvidia-smi
    package = pkgs.ollama-cuda;

    # Optional: preload models, see https://ollama.com/library
    #loadModels = [ "llama3.2:3b" "deepseek-r1:1.5b"];
  };
}