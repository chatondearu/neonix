# Pinned Cursor for x86_64-linux (AppImage), same layout as nixpkgs code-cursor.
{
  lib,
  stdenv,
  buildVscode,
  fetchurl,
  appimageTools,
  commandLineArgs ? "",
}: let
  inherit (stdenv) hostPlatform;

  sourcesJson = lib.importJSON ./sources.json;

  finalCommandLineArgs = "--update=false " + commandLineArgs;

  source = fetchurl {
    url = sourcesJson.source;
    hash = sourcesJson.hash;
  };
in
  lib.throwIfNot (hostPlatform.system == "x86_64-linux")
  "pkgs/cursor: only x86_64-linux is supported (see sources.json / update.sh)"
  (buildVscode rec {
    commandLineArgs = finalCommandLineArgs;
    inherit (sourcesJson) version vscodeVersion;

    pname = "cursor";
    useVSCodeRipgrep = false;

    executableName = "cursor";
    longName = "Cursor";
    shortName = "cursor";
    libraryName = "cursor";
    iconName = "cursor";

    src = appimageTools.extract {
      inherit pname version;
      src = source;
    };

    sourceRoot = "${pname}-${version}-extracted/usr/share/cursor";

    tests = {};

    updateScript = ./update.sh;

    patchVSCodePath = false;

    meta = {
      description = "AI-powered code editor built on vscode";
      homepage = "https://cursor.com";
      changelog = "https://cursor.com/changelog";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      maintainers = with lib.maintainers; [
        aspauldingcode
        prince213
        qweered
      ];
      platforms = ["x86_64-linux"];
      mainProgram = "cursor";
    };
  })
