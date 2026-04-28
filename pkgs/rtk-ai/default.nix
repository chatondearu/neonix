# Package definition for rtk (Rust Token Killer)
# https://github.com/rtk-ai/rtk
{ lib, stdenv, pkgs, rustPlatform, cargo, ... }:

stdenv.mkDerivation rec {
  pname = "rtk";
  version = "0.22.2";

  src = pkgs.fetchFromGitHub {
    owner = "rtk-ai";
    repo = "rtk";
    rev = "v${version}";
    hash = "sha256-0j2gh6zj2vja7h2xqji34wy3mzg5bhgq0h7gxfa24djg9ri87lvl";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "./Cargo.lock";
  };


  nativeBuildInputs = with pkgs; [
    cmake
    makeWrapper
  ];

  buildPhase = ''
    mkdir -p build && cd build
    cmake .. ${cmakeFlags}
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp rtk $out/bin/
    wrapProgram $out/bin/rtk
  '';

  meta = with lib; {
    description = "CLI proxy that reduces LLM token consumption by 60-90% on common dev commands";
    homepage = "https://github.com/rtk-ai/rtk";
    license = licenses.mit;
    maintainers = with maintainers; [ chaton ];
    mainProgram = "rtk";
  };
}
