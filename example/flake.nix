{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    cargo2nix-ifd = {
      # url = "github:kgtkr/cargo2nix-ifd";
      url = "path:../";
      inputs.cargo2nix.follows = "cargo2nix";
    };
  };

  outputs = { self, nixpkgs, flake-utils, cargo2nix, cargo2nix-ifd, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ cargo2nix.overlays.default ];
        };
        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        projectName = "hello";
        cargo2nix-ifd-lib = cargo2nix-ifd.mkLib pkgs;
        filteredSrc = cargo2nix-ifd-lib.filterSrc {
          src = ./.;
          inherit projectName;
        };
        generatedSrc = cargo2nix-ifd-lib.generateSrc {
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
          default = self.packages.${system}.hello;
        };
        devShells = {
          default = rustPkgs.workspaceShell { };
        };
      }
    );
}
