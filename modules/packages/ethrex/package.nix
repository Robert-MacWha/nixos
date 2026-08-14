{
  description = "ethrex + lighthouse node for the Hegotá testnet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";

    # Pull ethrex straight from main. Pin to a specific rev/tag once
    # you know which release you're targeting, e.g.:
    #   url = "github:lambdaclass/ethrex?ref=v16.0.0";
    ethrex-src = {
      url = "github:lambdaclass/ethrex";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
      flake-utils,
      ethrex-src,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        # ethrex pins Rust 1.93.0 in its rust-toolchain.toml (as of the
        # revision this flake was written against) — check
        # ethrex-src/rust-toolchain.toml if the build complains about
        # a version mismatch.
        rustToolchain = pkgs.rust-bin.stable."1.93.0".default.override {
          extensions = [ "rust-src" ];
        };

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolchain;
          rustc = rustToolchain;
        };

        nativeBuildDeps = with pkgs; [
          pkg-config
          clang
          cmake
          protobuf
        ];

        buildDeps =
          with pkgs;
          [ openssl ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.darwin.apple_sdk.frameworks.Security
            pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
          ];

        commonEnv = {
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
        };

        ethrex = rustPlatform.buildRustPackage (
          commonEnv
          // {
            pname = "ethrex";
            version = "hegota-git";
            src = ethrex-src;

            # First `nix build` will fail with a hash mismatch (or fail
            # to fetch git deps) — that's normal for a lockfile-based
            # build against a moving upstream repo. Copy the hash Nix
            # reports into `outputHashes` below if Cargo.lock pulls any
            # git dependencies (ethrex has ZK-prover crates that
            # sometimes do).
            cargoLock = {
              lockFile = "${ethrex-src}/Cargo.lock";
              # outputHashes = {
              #   "some-git-dep-0.0.0" = "sha256-AAAA...";
              # };
            };

            nativeBuildInputs = nativeBuildDeps;
            buildInputs = buildDeps;

            buildAndTestSubdir = "cmd/ethrex";
            doCheck = false; # full test suite is heavy; enable if you want it
          }
        );

        # Uses nixpkgs' own lighthouse package rather than building
        # from source — it's a normal package there, no reason to
        # reinvent it. The open question isn't packaging, it's
        # WHICH VERSION: nixpkgs.lighthouse tracks tagged releases,
        # and it's not confirmed here that any tagged release speaks
        # the FOCIL-era engine API pair (engine_newPayloadV6 /
        # engine_forkchoiceUpdatedV5) that Hegotá requires past its
        # fork boundary — the docs say an older client just halts
        # there, no degraded mode. Check
        # https://github.com/sigp/lighthouse for the relevant
        # FOCIL/Hegotá branch or release before you rely on this. If
        # you need an unreleased branch, override with:
        #   nixpkgs.lib.overrideDerivation pkgs.lighthouse (old: {
        #     src = pkgs.fetchFromGitHub {
        #       owner = "sigp"; repo = "lighthouse";
        #       rev = "<focil-branch-or-commit>";
        #       sha256 = "sha256-AAAA..."; # nix will report the real one
        #     };
        #   })
        # and swap that in below instead of pkgs.lighthouse.
        lighthouse = pkgs.lighthouse;

        # Reads the artifact bundle from ./network (or $NETWORK_DIR)
        # and starts ethrex per the "Run a node" instructions: genesis
        # + bootnode list, --nat.extip required (not --p2p.addr).
        runEthrex = pkgs.writeShellApplication {
          name = "run-ethrex";
          runtimeInputs = [
            ethrex
            pkgs.openssl
            pkgs.coreutils
          ];
          text = ''
            NETWORK_DIR="${"$"}{NETWORK_DIR:-./network}"
            JWT_SECRET="${"$"}{JWT_SECRET:-./secrets/jwt.hex}"

            if [ -z "${"$"}{EXTIP:-}" ]; then
              echo "Set EXTIP to your public IP (used for --nat.extip)." >&2
              exit 1
            fi
            if [ ! -f "$NETWORK_DIR/genesis.json" ]; then
              echo "Missing $NETWORK_DIR/genesis.json — drop the published artifact bundle there first." >&2
              exit 1
            fi
            if [ ! -f "$NETWORK_DIR/bootnodes.txt" ]; then
              echo "Missing $NETWORK_DIR/bootnodes.txt." >&2
              exit 1
            fi

            mkdir -p "$(dirname "$JWT_SECRET")"
            if [ ! -f "$JWT_SECRET" ]; then
              openssl rand -hex 32 | tr -d '\n' > "$JWT_SECRET"
            fi

            exec ethrex \
              --network "$NETWORK_DIR/genesis.json" \
              --bootnodes "$(paste -sd, "$NETWORK_DIR/bootnodes.txt")" \
              --authrpc.jwtsecret "$JWT_SECRET" \
              --nat.extip "$EXTIP" \
              --syncmode full \
              "$@"
          '';
        };

        # Consensus side. Adjust the exact CLI shape once you have the
        # real artifact bundle in hand — testnet-dir vs. explicit
        # --boot-nodes depends on how the bundle is laid out.
        runLighthouse = pkgs.writeShellApplication {
          name = "run-lighthouse";
          runtimeInputs = [
            lighthouse
            pkgs.coreutils
          ];
          text = ''
            NETWORK_DIR="${"$"}{NETWORK_DIR:-./network}"
            JWT_SECRET="${"$"}{JWT_SECRET:-./secrets/jwt.hex}"

            if [ ! -f "$JWT_SECRET" ]; then
              echo "Missing $JWT_SECRET — run run-ethrex first (or generate it yourself)." >&2
              exit 1
            fi

            BOOT_NODES_ARG=()
            if [ -f "$NETWORK_DIR/cl-bootnodes.txt" ]; then
              BOOT_NODES_ARG=(--boot-nodes "$(paste -sd, "$NETWORK_DIR/cl-bootnodes.txt")")
            fi

            exec lighthouse bn \
              --testnet-dir "$NETWORK_DIR" \
              "${"$"}{BOOT_NODES_ARG[@]}" \
              --execution-endpoint http://localhost:8551 \
              --execution-jwt "$JWT_SECRET" \
              --http \
              "$@"
          '';
        };
      in
      {
        packages = {
          inherit ethrex lighthouse;
          default = ethrex;
        };

        apps = {
          ethrex = {
            type = "app";
            program = "${ethrex}/bin/ethrex";
          };
          lighthouse = {
            type = "app";
            program = "${lighthouse}/bin/lighthouse";
          };
          run-ethrex = {
            type = "app";
            program = "${runEthrex}/bin/run-ethrex";
          };
          run-lighthouse = {
            type = "app";
            program = "${runLighthouse}/bin/run-lighthouse";
          };
        };

        devShells.default = pkgs.mkShell (
          commonEnv
          // {
            buildInputs = [
              ethrex
              lighthouse
              pkgs.openssl
              pkgs.jq
            ]
            ++ nativeBuildDeps;
          }
        );
      }
    );
}
