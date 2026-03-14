{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "openwork";
  version = "0.11.146";

  src = pkgs.fetchurl {
    url = "https://github.com/different-ai/openwork/releases/download/v${version}/openwork-desktop-linux-amd64.deb";
    sha256 = "sha256-YQyOh2DG3+myYbFV6UTcj5AlppV/ueg9tgZ/tMy7PQA="; 
  };

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = with pkgs; [
    at-spi2-atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    pcre2
    libsecret
    libsoup_3
    openssl
    pango
    webkitgtk_4_1
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    zlib
    stdenv.cc.cc.lib # Très important pour libstdc++.so.6 (souvent requis par Node/Bun)
    libGL
    libxkbcommon
    dconf
  ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    # On utilise /opt/openwork pour garder les noms de fichiers originaux intacts
    # et conserver la hiérarchie attendue par l'application.
    mkdir -p $out/opt/openwork $out/bin $out/share/applications $out/share/icons

    # 1. On copie TOUT ce qui est dans usr/bin vers /opt/openwork
    cp -r usr/bin/* $out/opt/openwork/
    
    # 2. On copie les icônes
    cp -r usr/share/icons/* $out/share/icons/ 2>/dev/null || true

    # 3. On crée les wrappers dans /bin qui pointent vers /opt
    # L'avantage : les exécutables dans /opt gardent leurs noms originaux (pas de .wrapped)
    
    makeWrapper $out/opt/openwork/OpenWork-Dev $out/bin/OpenWork-Dev \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}" \
      --set XDG_DATA_DIRS "$GSETTINGS_SCHEMAS_PATH:$out/share"

    makeWrapper $out/opt/openwork/opencode $out/bin/opencode \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}"

    # On s'assure que le serveur est aussi wrappé au cas où l'UI l'invoque par le PATH
    # ou si on a besoin de le débugger
    makeWrapper $out/opt/openwork/openwork-server $out/bin/openwork-server \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}"

    # 4. Correction du fichier .desktop pour qu'il pointe sur le wrapper dans $out/bin
    if [ -f usr/share/applications/OpenWork.desktop ]; then
      substituteInPlace usr/share/applications/OpenWork.desktop \
        --replace "Exec=opencode" "Exec=$out/bin/OpenWork-Dev" \
        --replace "Name=OpenCode" "Name=OpenWork"
      cp usr/share/applications/OpenWork.desktop $out/share/applications/
    fi

    # Astuce : Parfois les UI appellent le binaire de leur serveur via un chemin relatif strict.
    # Si le serveur cherche ses librairies mais qu'il est appelé directement par l'UI dans /opt, 
    # autoPatchelfHook s'en chargera.

    runHook postInstall
  '';
}