{
  lib,
  rustPlatform,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  pkg-config,
  wrapGAppsHook4,
  gtk3,
  webkitgtk_4_1,
  libsoup_3,
  openssl,
  pipewire,
  alsa-utils,
  makeWrapper,
}:
rustPlatform.buildRustPackage rec {
  pname = "goxlr-router";
  version = "0.1.0";
  src = ./.;

  cargoRoot = "src-tauri";

  cargoLock = {
    lockFile = ./src-tauri/Cargo.lock;
  };

  npmDeps = fetchNpmDeps {
    pname = "${pname}-npm-deps";
    inherit version src;
    hash = "sha256-TH3CfqaRTKC1bOQRCK2H0ZpnD/wJfrnopLxgikD0CwY=";
  };

  nativeBuildInputs = [
    npmHooks.npmConfigHook
    nodejs
    pkg-config
    wrapGAppsHook4
    makeWrapper
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libsoup_3
    openssl
  ];

  env.OPENSSL_NO_VENDOR = "1";

  doCheck = false;

  # buildRustPackage runs cargo in $src; this project keeps the crate under src-tauri/.
  preBuild = "";

  buildPhase = ''
    runHook preBuild
    npm run build
    pushd src-tauri
    cargo build --release --frozen --offline -j$NIX_BUILD_CORES
    popd
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 src-tauri/target/release/goxlr-router $out/bin/goxlr-router
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/goxlr-router \
      --prefix PATH : "${lib.makeBinPath [pipewire alsa-utils]}"
  '';

  meta = with lib; {
    description = "PipeWire audio graph switchboard UI (Vue + Tauri)";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "goxlr-router";
  };
}
