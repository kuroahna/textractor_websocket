{
  description = "Textractor WebSocket";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    crane.url = "github:ipetkov/crane";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      crane,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        crossCompileForX64 =
          let
            targetTriple = "x86_64-pc-windows-gnu";

            # Hack required to fix link errors with pthreads on stable 1.84.0
            # This does not seem to be required on nightly 1.86.0
            #
            # https://github.com/nix-community/naersk/issues/181#issuecomment-874352470
            fixLinkErrors = ''
              export CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS="-C link-args=''$(echo $NIX_LDFLAGS | tr ' ' '\n' | grep -- '^-L' | tr '\n' ' ')"
              export NIX_LDFLAGS=
            '';

            toolchain =
              p:
              p.rust-bin.stable.latest.default.override {
                targets = [ targetTriple ];
              };
            craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

            src = craneLib.cleanCargoSource ./.;

            commonArgs = {
              inherit src;
              strictDeps = true;
            };

            cargoArtifacts = craneLib.buildDepsOnly (
              commonArgs
              // {
                nativeBuildInputs = with pkgs; [
                  pkgsCross.mingwW64.stdenv.cc
                ];
                buildInputs = with pkgs; [
                  pkgsCross.mingwW64.windows.mingw_w64_pthreads
                ];

                preBuild = fixLinkErrors;

                buildPhaseCargoCommand = ''
                  cargo check --profile release --frozen --target ${targetTriple}
                  cargo build --profile release --frozen --target ${targetTriple} --workspace
                '';
                checkPhaseCargoCommand = ''
                  cargo test --profile release --frozen --target ${targetTriple} --workspace --no-run
                '';
              }
            );

            textractor_websocket = craneLib.buildPackage (
              commonArgs
              // {
                inherit cargoArtifacts;
                nativeBuildInputs = with pkgs; [
                  pkgsCross.mingwW64.stdenv.cc
                  wine64
                ];
                buildInputs = with pkgs; [
                  pkgsCross.mingwW64.windows.mingw_w64_pthreads
                ];

                preConfigure = ''
                  # Required for wine
                  export HOME=$(mktemp --directory)
                '';

                preBuild = fixLinkErrors;

                cargoExtraArgs = "--frozen --target ${targetTriple} --workspace";
                CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = "wine64";
              }
            );
          in
          {
            src = src;
            commonArgs = commonArgs;
            craneLib = craneLib;
            cargoArtifacts = cargoArtifacts;
            textractor_websocket = textractor_websocket;
            targetTriple = targetTriple;
          };

        crossCompileForX86 =
          let
            targetTriple = "i686-pc-windows-gnu";

            toolchain =
              p:
              p.rust-bin.stable.latest.default.override {
                extensions = [ "rust-src" ];
                targets = [ targetTriple ];
              };
            craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

            src = craneLib.cleanCargoSource ./.;

            # We need to vendor our dependencies since we're recompiling rust
            # std
            #
            # https://github.com/ipetkov/crane/issues/285
            cargoVendorDir = craneLib.vendorMultipleCargoDeps {
              cargoLockList = [
                ./Cargo.lock
                "${pkgs.rust-bin.stable.latest.rust-src}/lib/rustlib/src/rust/library/Cargo.lock"
              ];
            };

            commonArgs = {
              inherit src;
              inherit cargoVendorDir;
              strictDeps = true;
            };

            textractor_websocket = craneLib.buildPackage (
              commonArgs
              // {
                # Trying to compile with -Zbuild-std with cargoArtifacts using
                # craneLib.buildDepsOnly which splits the dependency crates into
                # a separate derivation throws a compile error where we get
                # undefined reference to _Unwind_Resume despite passing in
                # panic=abort. Setting to null allows us to get around this
                # issue where crane will compile the crate without splitting the
                # dependency into a separate derivation.
                cargoArtifacts = null;

                nativeBuildInputs = with pkgs; [
                  pkgsCross.mingw32.stdenv.cc
                  wine
                  jq
                ];
                buildInputs = with pkgs; [
                  pkgsCross.mingw32.windows.mingw_w64_pthreads
                ];

                # Despite compiling with panic=abort, it still makes references
                # to unwind functions. It should be impossible to call this
                # function with panic=abort enabled
                #
                # https://github.com/rust-lang/rust/issues/47493
                postPatch = ''
                  cat << EOF >> src/lib.rs
                  #[no_mangle]
                  extern "C" fn _Unwind_GetLanguageSpecificData() -> ! {
                      unreachable!("Unwinding not supported");
                  }
                  EOF
                '';

                preConfigure = ''
                  # Required for wine
                  export HOME=$(mktemp --directory)
                '';

                # Enable unstable features in stable
                RUSTC_BOOTSTRAP = 1;

                # Compiling for i686-pc-windows-gnu results in undefined
                # references to _Unwind_Resume linker errors because
                # i686-pc-windows-gnu has references to unwind in rtstartup
                # whereas x86_64 does not. Compiling with panic=abort should
                # remove all references to unwind, but there is a bug where it
                # is ignored. Hence, we need to recompile rust std with our own
                # custom target which removes the link to rtstartup
                #
                # https://github.com/rust-lang/rust/issues/133826
                postConfigure = ''
                  rustc -Z unstable-options --print target-spec-json --target "i686-pc-windows-gnu" > target.json
                  jq 'del(."pre-link-objects", ."pre-link-objects-fallback", ."post-link-objects", ."post-link-objects-fallback")' target.json > i686-pc-windows-gnu.json
                '';

                CARGO_TARGET_I686_PC_WINDOWS_GNU_RUSTFLAGS = "-C panic=abort -Zpanic_abort_tests";

                buildPhaseCargoCommand = ''
                  export cargoBuildLog=$(mktemp)
                  cargo build -Zbuild-std=std,panic_abort --profile release --frozen --target i686-pc-windows-gnu.json --workspace --message-format json-render-diagnostics > $cargoBuildLog
                '';
                cargoTestCommand = "cargo test -Zbuild-std=std,panic_abort --profile release --frozen --target i686-pc-windows-gnu.json --workspace";
                CARGO_TARGET_I686_PC_WINDOWS_GNU_RUNNER = "wine";
              }
            );
          in
          {
            textractor_websocket = textractor_websocket;
          };
      in
      {
        formatter = pkgs.nixfmt-rfc-style;
        packages.default = crossCompileForX64.textractor_websocket;
        packages.x86 = crossCompileForX86.textractor_websocket;
        checks = {
          textractor_websocket_x64 = crossCompileForX64.textractor_websocket;

          clippy = crossCompileForX64.craneLib.cargoClippy (
            crossCompileForX64.commonArgs
            // {
              cargoArtifacts = crossCompileForX64.cargoArtifacts;
              cargoClippyExtraArgs = "--target ${crossCompileForX64.targetTriple} -- --deny warnings";
            }
          );

          format = crossCompileForX64.craneLib.cargoFmt {
            src = crossCompileForX64.src;
          };

          toml_format = crossCompileForX64.craneLib.taploFmt {
            src = pkgs.lib.sources.sourceFilesBySuffices crossCompileForX64.src [ ".toml" ];
          };

          deny = crossCompileForX64.craneLib.cargoDeny { src = crossCompileForX64.src; };
        };
        devShells.default = crossCompileForX64.craneLib.devShell {
          checks = self.checks.${system};

          packages = with pkgs; [
            rust-analyzer
          ];

          # fixes: the cargo feature `public-dependency` requires a nightly
          # version of Cargo, but this is the `stable` channel
          #
          # This enables unstable features with the stable compiler
          # Remove once this is fixed in stable
          #
          # https://github.com/rust-lang/rust/issues/112391
          # https://github.com/rust-lang/rust-analyzer/issues/15046
          RUSTC_BOOTSTRAP = 1;
        };
      }
    );
}
