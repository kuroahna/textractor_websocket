{
  description = "textractor_websocket";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    # self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        overlays = [(import rust-overlay)];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        nativeBuildInputs = with pkgs; [glibc];
        buildInputs = with pkgs; [
          (rust-bin.selectLatestNightlyWith (toolchain:
            toolchain.default.override {
              targets = ["x86_64-pc-windows-gnu"];
            }))
          musl
        ];
      in
        with pkgs; {
          devShells.default = mkShell {
            inherit nativeBuildInputs buildInputs;
          };
          packages."x86_64-linux".default = derivation {
            inherit system;
          };
          formatter = builtins.mapAttrs (system: pkgs: pkgs.alejandra) nixpkgs.legacyPackages;
        }
    );
}
