{
  lib,
  stdenvNoCC,
  buildNpmPackage,
  fetchurl,
  versionCheckHook,
  writableTmpDirAsHomeHook,
}: let
  sourcesJson = lib.importJSON ./sources.json;
in
  buildNpmPackage (finalAttrs: {
    pname = "gitnexus";
    version = sourcesJson.version;

    # Official CLI distribution: https://www.npmjs.com/package/gitnexus
    src = fetchurl {
      url = "https://registry.npmjs.org/gitnexus/-/gitnexus-${finalAttrs.version}.tgz";
      hash = sourcesJson.hash;
    };

    sourceRoot = "package";
    npmDepsHash = sourcesJson.npmDepsHash;

    postPatch = ''
      cp ${./package-lock.json} package-lock.json

      # Published tarball already contains dist/; skip lifecycle builds during npm ci.
      node <<'EOF'
      const fs = require("fs");
      const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
      pkg.scripts = {};
      fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
      EOF
    '';

    npmFlags = [
      "--ignore-scripts"
    ];

    dontNpmBuild = true;

    nativeInstallCheckInputs = [
      versionCheckHook
      writableTmpDirAsHomeHook
    ];
    doInstallCheck = true;
    versionCheckKeepEnvironment = ["HOME"];
    versionCheckProgramArg = "--version";

    updateScript = ./update.sh;

    meta = with lib; {
      description = "GitNexus - AI-powered Git workflows";
      homepage = "https://github.com/abhigyanpatwari/GitNexus";
      license = licenses.mit;
      maintainers = with maintainers; [chatondearu];
      sourceProvenance = with sourceTypes; [binaryBytecode];
      platforms = ["x86_64-linux"];
      mainProgram = "gitnexus";
    };
  })
