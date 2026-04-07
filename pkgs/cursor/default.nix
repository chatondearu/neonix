{
  lib,
  stdenv,
  buildVscode,
  fetchurl,
  appimageTools,
  commandLineArgs ? "",
}: let
  finalCommandLineArgs = "--update=false " + commandLineArgs;

  sourcesJson = lib.importJSON ./sources.json;
  source = fetchurl {
    url = sourcesJson.source;
    hash = sourcesJson.hash;
  };
in
  buildVscode rec {
    inherit (sourcesJson) version vscodeVersion;
    commandLineArgs = finalCommandLineArgs;

    pname = "cursor";

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

    # Cursor has no wrapper script.
    patchVSCodePath = false;

    meta = {
      description = "AI-powered code editor built on vscode";
      homepage = "https://cursor.com";
      changelog = "https://cursor.com/changelog";
      license = lib.licenses.unfree;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      maintainers = with lib.maintainers; [
        aspauldingcode
        prince213
        qweered
      ];
      platforms = [
        "x86_64-linux"
      ];
      mainProgram = "cursor";
    };
  }
