{
  description = "attached_dashboard — development environment";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.beam29Packages.elixir_1_20
            pkgs.nodejs_24
            pkgs.imagemagick
            pkgs.vips
            pkgs.ffmpeg_7
            pkgs.poppler-utils
            pkgs.mupdf
            pkgs.chromedriver
          ];

          shellHook = ''
            mkdir -p .nix/mix .nix/hex
            export HEX_HOME=$PWD/.nix/hex MIX_HOME=$PWD/.nix/mix
            export PATH=$MIX_HOME/bin:$HEX_HOME/bin:$PATH
          '';
        };
      });
    };
}
