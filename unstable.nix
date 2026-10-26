# This overlay intentionally keeps unstable exposure narrow.
# Rule: add only components that are justified by desktop/gaming compatibility.
# See doc/version-governance.md for update policy and validation routine.
{
  inputs,
  config,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: let
      unstable-pkgs = import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config = config.nixpkgs.config;
      };
      # cursor-cli: bundled node SIGSEGV after autoPatchelf with patchelf 0.19.2
      # https://github.com/NixOS/nixpkgs/issues/579143
      patchelf_0_15_2 =
        unstable-pkgs.patchelf.overrideAttrs (finalAttrs: previousAttrs: {
          version = "0.15.2";
          src = unstable-pkgs.fetchurl {
            url = "https://github.com/NixOS/patchelf/releases/download/${finalAttrs.version}/patchelf-${finalAttrs.version}.tar.bz2";
            hash = "sha256-F3RfVkFZyOIo/EEtplogSLhGxLa0Igt3y/IkFuAvLXw=";
          };
        });
      cursor-cli = unstable-pkgs.cursor-cli.overrideAttrs (old: {
        nativeBuildInputs = [patchelf_0_15_2] ++ (old.nativeBuildInputs or []);
      });
      unstable = unstable-pkgs // {inherit cursor-cli;};
    in {
      unstable = unstable; # Provides pkgs.unstable for explicit opt-in usage

      # Dank Material Shell stack (paired with niri/quickshell integration)
      dms-shell = unstable-pkgs.dms-shell;
      dms-greeter = unstable-pkgs.dms-greeter;
      dgop = unstable-pkgs.dgop; # System monitoring widgets

      # Niri compositor and related module path in desktop/niri/niri.nix
      niri = unstable-pkgs.niri;

      # Steam remains unstable here for current VR/gaming behavior consistency.
      # Re-evaluate periodically with release notes + smoke tests.
      steam = unstable-pkgs.steam;
    })

    # Nixpkgs-XR - https://github.com/nix-community/nixpkgs-xr
    inputs.nixpkgs-xr.overlays.default

    # aarch64-only patch must not apply on x86_64 (breaks xrizer → wivrn when garnix cache misses).
    (final: prev: {
      # Quest client (store / APK) is v26.9. nixos-26.05 and our locked
      # nixos-unstable still package 26.6.2; nixpkgs-xr overlays git HEAD
      # onto that recipe. Pin the tagged release so the protocol matches.
      wivrn = prev.wivrn.overrideAttrs (old: let
        src = prev.fetchFromGitHub {
          owner = "wivrn";
          repo = "wivrn";
          rev = "v26.9";
          hash = "sha256-/kXgbku/4EeYY5YTwtY71csgxOP8bRACLqOvKXolg5g=";
        };
        monado = prev.applyPatches {
          src = prev.fetchFromGitLab {
            domain = "gitlab.freedesktop.org";
            owner = "monado";
            repo = "monado";
            rev = "f037264d23e2472a444a157370647fcd601ed81b";
            hash = "sha256-exHbecudAy57szL7kut7/fBYCoekEs3riZzhMtFWS/c=";
          };
          postPatch = ''
            ${src}/patches/apply.sh ${src}/patches/monado/*
          '';
        };
      in {
        version = "26.9";
        inherit src monado;
        postUnpack = ''
          ourMonadoRev="${monado.src.rev}"
          theirMonadoRev=$(cat ${src.name}/monado-rev)
          if [ ! "$theirMonadoRev" == "$ourMonadoRev" ]; then
            echo "Our Monado source revision doesn't match CMakeLists.txt." >&2
            echo " theirs: $theirMonadoRev" >&2
            echo " ours: $ourMonadoRev" >&2
            return 1
          fi
        '';
        cmakeFlags =
          (
            lib.filter (
              flag: let
                s = toString flag;
              in
                !(lib.hasInfix "GIT_DESC" s
                  || lib.hasInfix "GIT_COMMIT" s
                  || lib.hasInfix "GIT_TAG" s
                  || lib.hasInfix "FETCHCONTENT_SOURCE_DIR_MONADO" s)
            )
            (old.cmakeFlags or [])
          )
          ++ [
            (lib.cmakeFeature "GIT_TAG" "v26.9")
            (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_MONADO" "${monado}")
          ];
      });

      xrizer = prev.xrizer.overrideAttrs (oldAttrs: {
        patches =
          lib.filter (
            p:
              prev.stdenv.hostPlatform.isAarch64
              || !lib.hasInfix "aarch64" (toString p)
          )
          (oldAttrs.patches or []);
      });
    })
  ];
}
