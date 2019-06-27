({
    pkgs
  , buildPackages
  , lib
  , resolver
  , packageFun
  , config
  , buildConfig
  , cargo
  , rustc
}:
  let
    inherit (lib) recursiveUpdate;
    resolver-overlay = {
      resolver = (args@{
          source
        , name
        , version
        , sha256
        , source-info
      }:
        if source == "registry+https://github.com/rust-lang/crates.io-index" then
          pkgs.rustBuilder.rustLib.fetchCratesIo {
            inherit name;
            inherit version;
            inherit sha256;
          }
        else
          resolver args);
    };
    config' = lib.recursiveUpdate config resolver-overlay;
    buildConfig' = lib.recursiveUpdate buildConfig resolver-overlay;
    bootstrap = pkgs.rustBuilder.makePackageSet {
      inherit cargo;
      inherit rustc;
      inherit packageFun;
      rustPackageConfig = config';
      buildRustPackages = buildPackages.rustBuilder.makePackageSet {
        inherit cargo;
        inherit rustc;
        inherit packageFun;
        rustPackageConfig = config';
      };
    };
    features = lib.fold lib.recursiveUpdate {
    } [
      (bootstrap.unknown.cargo2nix."0.1.0".computePackageFeatures [
      ])
    ];
  in
  pkgs.rustBuilder.makePackageSet {
    inherit cargo;
    inherit rustc;
    inherit packageFun;
    rustPackageConfig = lib.recursiveUpdate config' {
      features = features.${pkgs.stdenv.hostPlatform.config};
    };
    buildRustPackages = buildPackages.rustBuilder.makePackageSet {
      inherit cargo;
      inherit rustc;
      inherit packageFun;
      rustPackageConfig = lib.recursiveUpdate buildConfig' {
        features = features.${buildPackages.stdenv.hostPlatform.config};
      };
    };
  })