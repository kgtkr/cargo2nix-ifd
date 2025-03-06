{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    cargo2nix-ifd = {
      url = "github:kgtkr/cargo2nix-ifd";
      inputs.cargo2nix.follows = "cargo2nix";
    };
  };

  outputs = { self, nixpkgs, flake-utils, cargo2nix, cargo2nix-ifd, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ cargo2nix.overlays.default ];
        };
        projectName = "hello";
        filteredSrc = cargo2nix-ifd.lib.${system}.filterSrc {
          src = ./.;
          inherit projectName;
        };
        generatedSrc = cargo2nix-ifd.lib.${system}.generateSrc {
          src = filteredSrc;
          inherit projectName rustToolchain;
        };
        rustPkgs = pkgs.rustBuilder.makePackageSet {
          packageFun = import "${generatedSrc}/Cargo.nix";
          inherit rustToolchain;
        };
        hello = rustPkgs.workspace.hello { };
      in
      {
        packages = {
          inherit hello;
        };
        defaultPackage = self.packages.${system}.hello;
        devShell = rustPkgs.workspaceShell {
        };
      }
    );
}
