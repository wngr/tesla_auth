{
  description = "tesla_auth";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rustVersion = (pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml);
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustVersion;
          rustc = rustVersion;
        };

        rustBuild = rustPlatform.buildRustPackage {
          pname = "tesla_auth";
          version = "0.9.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          nativeBuildInputs =
            with pkgs;[
              (rustVersion.override { extensions = [ "rust-src" ]; })
              pkg-config
              wrapGAppsHook
            ];
          buildInputs =
            with pkgs; [
              xdotool
              libsoup_3
              webkitgtk_4_1
              glib-networking
            ];
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = rec {
          rustPackage = rustBuild;
          default = rustPackage;
        };
        devShell = pkgs.mkShell {
          buildInputs = self.packages.${system}.rustPackage.buildInputs;
          nativeBuildInputs = self.packages.${system}.rustPackage.nativeBuildInputs;
        };
      });
}
