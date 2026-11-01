# Forked packages

Each fork is a self-contained package in `packages/<name>/default.nix`. Do not wrap a nixpkgs package with `overrideAttrs` for a fork.

The pattern:

- The source is a flake input (`flake = false`) pinned in `flake.lock`, or a `fetchFromGitHub` inside the package. The host passes `src` through `callPackage`.
- Every external artifact is pinned explicitly: prebuilt archives, npm dependency hashes, and the source revision used for build metadata.
- Dependencies and CMake/build flags are listed in the package. It does not inherit a nixpkgs derivation or its internal pins.
- Adaptations that exist only for Nix (removing the npm invocation, using system Boost, toolchain flags) live in the package's `postPatch`. Source changes that are more than a one-line substitution belong in `packages/<name>/patches/` and are applied with `patches = [ ... ];`.
- Expose the package as `packages.<system>.<name>` in `flake.nix` and call it from hosts with `pkgs.callPackage`.
- If the fork is a background or menu bar app, run it with a per-user `launchd.agents` service in the host. Do not add a terminal wrapper and do not require a terminal session.
- Scope `meta.platforms` and the dependencies to the systems this repository builds.
- When the fork or upstream moves, diff against the nixpkgs recipe if one exists and update the pins in the package. The package is the single source of truth.

`packages/sunshine` is the reference implementation:

- source: `inputs.sunshine` at `fix/macos-4k60`
- FFmpeg: the `Darwin-arm64` archive for the fork's `third-party/build-deps` tag, `v2026.1017.131201`
- web UI: `buildNpmPackage` with the fork's `package-lock.json` hash
- Nix adaptations: `postPatch` for npm, Boost, and `-fexperimental-library`
- build metadata: `BUILD_VERSION`, `BRANCH`, `COMMIT`
- one Qt `wrapProgram` in `postFixup`
- background launch: `launchd.agents.sunshine` in `hosts/kieran-m4pro`
