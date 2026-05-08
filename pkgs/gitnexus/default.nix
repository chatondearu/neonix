{
  lib,
  stdenvNoCC,
  gitMinimal,
  fetchFromGitHub,
  makeBinaryWrapper,
  nodejs,
  installShellFiles,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}:

let
  sourcesJson = lib.importJSON ./sources.json;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gitnexus";
  version = sourcesJson.version;
  sourceRoot = "source/gitnexus";

  # https://github.com/abhigyanpatwari/GitNexus
  src = fetchFromGitHub {
    owner = "abhigyanpatwari";
    repo = "GitNexus";
    tag = "v${finalAttrs.version}";
    hash = sourcesJson.hash;
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${finalAttrs.pname}-node_modules";
    inherit (finalAttrs) version src;
    sourceRoot = "source/gitnexus";

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      gitMinimal
      nodejs
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      NPM_CONFIG_OPTIONAL=false npm ci \
        --ignore-scripts \
        --no-audit \
        --no-fund

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R node_modules $out/

      runHook postInstall
    '';

    # NOTE: Required else we get errors that our fixed-output derivation references store paths
    dontFixup = true;

    outputHash = sourcesJson.node_modules_hash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };

  nativeBuildInputs = [
    nodejs
    installShellFiles
    makeBinaryWrapper
    writableTmpDirAsHomeHook
  ];

  configurePhase = ''
    runHook preConfigure

    cp -R ${finalAttrs.node_modules}/node_modules .
    patchShebangs node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    npm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 dist/cli/index.js $out/libexec/gitnexus.js
    makeBinaryWrapper ${nodejs}/bin/node $out/bin/gitnexus \
      --add-flags $out/libexec/gitnexus.js
    wrapProgram $out/bin/gitnexus \
      --prefix PATH : ${lib.makeBinPath [ ]}

    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
    installShellCompletion --cmd gitnexus \
      --bash <($out/bin/gitnexus completion --bash) \
      --zsh <($out/bin/gitnexus completion --zsh)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  doInstallCheck = true;
  versionCheckKeepEnvironment = [ "HOME" ];
  versionCheckProgramArg = "--version";

  passthru = {
    node_modules = finalAttrs.node_modules;
  };

  updateScript = ./update.sh;

  meta = with lib; {
    description = "GitNexus - AI-powered Git workflows";
    homepage = "https://github.com/abhigyanpatwari/GitNexus";
    license = licenses.mit;
    maintainers = with maintainers; [ chatondearu ];
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = [
      "x86_64-linux"
    ];
    mainProgram = "gitnexus";
  };
})
