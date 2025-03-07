# cargo2nix IFD
A small utility to do IFD with cargo2nix.

Cargo2nix is ​​a great tool for creating derivations for each crate, but it doesn't support IFD, so maintaining the `Cargo.nix` file can be a pain. So I created a cargo2nix version of crate2nix's `generatedCargoNix`.

## Usage
```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [ cargo2nix.overlays.default ];
};
rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
cargo2nix-ifd-lib = cargo2nix-ifd.mkLib pkgs;
generatedSrc = cargo2nix-ifd-lib.generateSrc {
  src = ./.;
  inherit rustToolchain;
};
rustPkgs = pkgs.rustBuilder.makePackageSet {
  # Cargo.nix is ​​generated automatically
  packageFun = import "${generatedSrc}/Cargo.nix";
  inherit rustToolchain;
};
```
