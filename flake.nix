{
  description = "OpenRGB Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
      in {
        packages.openrgb = pkgs.stdenv.mkDerivation {
          pname = "openrgb";
          version = "master";

          src = pkgs.fetchFromGitLab {
            owner = "CalcProgrammer1";
            repo = "OpenRGB";
            rev = "236e67e46bd63b99f94c4caf6f235dc0287b0e4a";
            hash = "sha256-9q6g145csgtdGHJ4b7SEXqUcKVRm0sO6ojF4o45GfXc=";
          };

          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.libsForQt5.qmake
            pkgs.libsForQt5.wrapQtAppsHook
          ];

          buildInputs = [
            pkgs.libusb1
            pkgs.hidapi
            pkgs.mbedtls_2
            pkgs.libsForQt5.qtbase
            pkgs.libsForQt5.qttools
            pkgs.libsForQt5.qtwayland
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp openrgb $out/bin/
          '';

          # Install OpenRGB's udev rules into /lib/udev/rules.d
          installUdevRulesPhase = ''
            mkdir -p $out/lib/udev/rules.d
            cp rules.d/60-openrgb.rules $out/lib/udev/rules.d/
          '';

          meta = with lib; {
            description = "Open source RGB lighting control";
            homepage = "https://gitlab.com/CalcProgrammer1/OpenRGB";
            license = licenses.gpl2Plus;
            platforms = platforms.linux;
            mainProgram = "openrgb";
          };
        };

        defaultPackage = self.packages.${system}.openrgb;
      });
}
