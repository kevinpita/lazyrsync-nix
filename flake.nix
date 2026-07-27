{
  description = "Nix flake for lazyrsync, a friendly terminal UI for rsync";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    let
      overlay = final: prev: {
        lazyrsync = final.callPackage ./package.nix { };
      };
    in
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
          lazyrsyncApp = {
            type = "app";
            program = "${pkgs.lazyrsync}/bin/lazyrsync";
            meta.description = pkgs.lazyrsync.meta.description;
          };
        in
        {
          packages = {
            default = pkgs.lazyrsync;
            lazyrsync = pkgs.lazyrsync;
          };

          apps = {
            default = lazyrsyncApp;
            lazyrsync = lazyrsyncApp;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              gh
              nixpkgs-fmt
            ];
          };
        }
      )
    // {
      overlays.default = overlay;
    };
}
