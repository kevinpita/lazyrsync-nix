# lazyrsync-nix

Always up-to-date Nix package for [lazyrsync](https://github.com/westpoint-io/lazyrsync), a friendly terminal UI for rsync.

## Quick Start

```bash
nix run github:kevinpita/lazyrsync-nix
```

## Install

```bash
nix profile install github:kevinpita/lazyrsync-nix
```

The package includes `rsync` and OpenSSH on its runtime `PATH`.

## Use In A Flake

```nix
{
  inputs.lazyrsync-nix.url = "github:kevinpita/lazyrsync-nix";

  outputs = { lazyrsync-nix, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          lazyrsync-nix.packages.${system}.default
        ];
      };
    };
}
```

## Development

```bash
nix build .#lazyrsync
./result/bin/lazyrsync --version
```

## Updates

The update workflow checks upstream releases hourly and can also be run manually from GitHub Actions. When a new release exists, it updates `package.nix`, refreshes the fixed-output hashes, creates a pull request, and enables auto-merge.

Manual update:

```bash
./scripts/update.sh --check
./scripts/update.sh --version 0.1.1
```
