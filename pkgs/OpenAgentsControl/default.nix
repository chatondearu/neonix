{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
, bash
, curl
, jq
, cacert
}:

stdenvNoCC.mkDerivation rec {
  pname = "oac-installer";
  version = "main";

  # On télécharge directement le script d'installation
  src = fetchurl {
    url = "https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/refs/heads/main/install.sh";
    # Pensez à remplacer ce fakeHash par le vrai hash via :
    # nix-prefetch-url https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/refs/heads/main/install.sh
    hash = "sha256-UOY6OQQRyVWWIRPOei1ZpQkpdG6a9tOMDIMKLuOP1hY=";
  };

  # Ce n'est pas une archive, pas besoin de la décompresser
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    
    # On copie le script et on le rend exécutable
    cp $src $out/bin/oac-install
    chmod +x $out/bin/oac-install

    # L'étape patchShebangs est cruciale sur NixOS pour remplacer le "#!/usr/bin/env bash"
    patchShebangs $out/bin/oac-install

    # wrapProgram garantit que le script trouvera TOUJOURS bash, curl et jq,
    # même si l'utilisateur ne les a pas dans son environnement global.
    # On injecte aussi les certificats CA pour que curl fonctionne sans erreur SSL.
    wrapProgram $out/bin/oac-install \
      --prefix PATH : ${lib.makeBinPath [ bash curl jq ]} \
      --set CURL_CA_BUNDLE "${cacert}/etc/ssl/certs/ca-bundle.crt"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Interactive installer for OpenCode agents, commands, tools, and plugins";
    homepage = "https://github.com/darrenhinde/OpenAgentsControl";
    platforms = platforms.unix;
  };
}