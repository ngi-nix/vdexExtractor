{
  description = "vdexExtractor flake";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";
  inputs.vdexExtractor = {
    url = "github:anestisb/vdexExtractor";
    flake = false;
  };

  outputs = { self, nixpkgs, vdexExtractor }:
    let
      version = builtins.substring 0 8 vdexExtractor.lastModifiedDate;
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = final: prev: {
        vdexExtractor = with final; stdenv.mkDerivation rec {
          pname = "vdexExtractor";
          inherit version;

          src = vdexExtractor;

          # No tests
          doCheck = false;

          buildPhase = ''
            bash ./make.sh
          '';

          installPhase = ''
            install -D bin/vdexExtractor $out/bin/vdexExtractor
          '';

          nativeBuildInputs = [
            zlib
          ];

          NIX_CFLAGS_COMPILE = [
            "-Wno-error=stringop-truncation"
          ];

          meta = with lib; {
            description = ''
              Tool to decompile & extract Android Dex bytecode from Vdex files
            '';
            homepage = "https://github.com/anestisb/vdexExtractor";
            license = with licenses; [ asl20 ];
            platforms = platforms.linux;
            maintainers = with maintainers; [ ambroisie ];
          };
        };
      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) vdexExtractor;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.vdexExtractor);

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) vdexExtractor;
      });
    };
}
