{
  lib,
  llama-cpp,
  fetchurl,
  stdenvNoCC,
  autoPatchelfHook,
  makeWrapper,
  sourcesJson ? lib.importJSON ./sources.json,
}: let
  inherit (sourcesJson) build;
in
  if build == "prebuilt-cpu"
  then
    import ./prebuilt.nix {
      inherit
        lib
        fetchurl
        stdenvNoCC
        autoPatchelfHook
        makeWrapper
        sourcesJson
        ;
    }
  else if build == "nixpkgs-cuda"
  then
    (llama-cpp.override {
      cudaSupport = true;
      rocmSupport = false;
      metalSupport = false;
      blasSupport = true;
    }).overrideAttrs (oldAttrs: {
      cmakeFlags =
        (oldAttrs.cmakeFlags or [])
        ++ [
          "-DCMAKE_CUDA_ARCHITECTURES=${sourcesJson.cudaArchitectures or "86"}"
        ];
      meta =
        (oldAttrs.meta or {})
        // {
          description = "llama.cpp from nixpkgs with CUDA (sm_${sourcesJson.cudaArchitectures or "86"})";
        };
    })
  else lib.throw "pkgs/llama-cpp: unsupported build mode '${build}' (use nixpkgs-cuda or prebuilt-cpu)"
