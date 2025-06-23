{
  inputs = {
    cargo2nix.url = "github:cargo2nix/cargo2nix";
    # for tools.nix
    crate2nix = {
      url = "github:nix-community/crate2nix";
      flake = false;
    };
    # for lib/filterCargoSources.nix
    crane = {
      url = "github:ipetkov/crane";
      flake = false;
    };
  };

  outputs = { cargo2nix, crate2nix, crane, ... }:
    {
      mkLib = pkgs:
        let
          tools = pkgs.callPackage "${crate2nix}/tools.nix" { inherit pkgs; };
          filterCargoSources = pkgs.callPackage "${crane}/lib/filterCargoSources.nix" { };
        in
        {
          generateSrc =
            { src
            , rustToolchain
            , projectName ? "project"
            , name ? "${projectName}-generated-src"
            }:
            let
              vendor = tools.internal.vendorSupport {
                crateDir = src;
                lockFiles = [ "${src}/Cargo.lock" ];
              };
              generatedSrc = pkgs.stdenv.mkDerivation {
                inherit name src;
                buildInputs = [ rustToolchain cargo2nix.packages.${pkgs.stdenv.buildPlatform.system}.cargo2nix ];
                buildPhase = ''
                  export HOME=/tmp/home
                  export CARGO_HOME="$HOME/cargo"
                  mkdir -p $CARGO_HOME

                  cp ${vendor.cargoConfig} $CARGO_HOME/config
                  CARGO_OFFLINE=true cargo2nix --locked
                '';

                installPhase = ''
                  mkdir -p $out

                  cp -r $src/. $out/
                  cp Cargo.nix $out/
                '';

              };
            in
            generatedSrc;
          filterSrc =
            { src
            , projectName ? "project"
            , name ? "${projectName}-filtered-src"
            , andFilter ? path: type: true
            , orFilter ? path: type: false
            }:
            let
              filter = path: type: (filterCargoSources path type) && (andFilter path type) || (orFilter path type);
            in
            pkgs.lib.cleanSourceWith {
              inherit name src filter;
            };
        };
    };
}
