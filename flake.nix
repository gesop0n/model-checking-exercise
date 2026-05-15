{
  description = "model-checking-exercise";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "aarch64-darwin"
      ];
      forEachSystem =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      formatter = forEachSystem (pkgs: pkgs.nixfmt-tree);

      devShells = forEachSystem (pkgs: {
        default =
          let
            nusmv =
              if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
                pkgs.stdenv.mkDerivation {
                  pname = "nusmv";
                  version = "2.7.0";
                  src = pkgs.fetchurl {
                    url = "https://nusmv.fbk.eu/distrib/2.7.0/NuSMV-2.7.0-macos-universal.tar.xz";
                    sha256 = "098wllv4yx284qv9nsi8kd5pgh10cr1hig01a1p2rxgfmrki52wm";
                  };
                  buildInputs = [ pkgs.gmp ];
                  dontBuild = true;
                  installPhase = ''
                    runHook preInstall
                    mkdir -p $out/bin
                    cp bin/NuSMV $out/bin/nusmv
                    chmod +w $out/bin/nusmv
                    install_name_tool \
                      -change /opt/homebrew/opt/gmp/lib/libgmp.10.dylib \
                      ${pkgs.gmp}/lib/libgmp.10.dylib \
                      $out/bin/nusmv
                    /usr/bin/codesign --force -s - $out/bin/nusmv
                    runHook postInstall
                  '';
                }
              else
                pkgs.nusmv;
          in
            pkgs.mkShell {
          packages = [
            nusmv
          ];

        };
      });
    };
}
