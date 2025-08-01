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


          postPatch = ''
            patchShebangs scripts/build-udev-rules.sh
          '';

          buildPhase = ''
            runHook preBuild

            mkdir build
            cd build

            qmake ../OpenRGB.pro
            make -j$NIX_BUILD_CORES

            ../scripts/build-udev-rules.sh ../ 59deaad070bfb591c458df9a6e3a62decb36282b

            cd ..

            runHook postBuild
          '';


           installPhase = ''
            mkdir -p $out/bin
            cp ./build/openrgb $out/bin/

            mkdir -p $out/share/applications
            cat > $out/share/applications/openrgb.desktop <<EOF
[Desktop Entry]
Name=OpenRGB
Comment=Control RGB lighting
Exec=$out/bin/openrgb
Icon=openrgb
Terminal=false
Type=Application
Categories=Utility;
EOF
          
            mkdir -p $out/lib/udev/rules.d
            substitute ./build/60-openrgb.rules $out/lib/udev/rules.d/60-openrgb.rules \
              --replace "/usr/bin/env" "${pkgs.coreutils}/bin/env"
          '';


          meta = with lib; {
            description = "Open source RGB lighting control";
            homepage = "https://gitlab.com/CalcProgrammer1/OpenRGB";
            license = licenses.gpl2Plus;
            platforms = platforms.linux;
            mainProgram = "openrgb";
          };
        };

        devShells.default = pkgs.mkShell {
          name = "openrgb-dev";

          nativeBuildInputs = [
            pkgs.pkg-config
            pkgs.libsForQt5.qmake
          ];

          buildInputs = [
            pkgs.libusb1
            pkgs.hidapi
            pkgs.mbedtls_2
            pkgs.libsForQt5.qtbase
            pkgs.libsForQt5.qttools
            pkgs.libsForQt5.qtwayland
          ];
        };

        defaultPackage = self.packages.${system}.openrgb;
      });
}
