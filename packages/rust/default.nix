# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ import-cargo, fenix, rust-analyzer-src, pkgs, system, ... }:
let
  importCargo = import-cargo.builders.importCargo;
in
if fenix.packages ? "${system}" then
  rec {
    rust-toolchain = fenix.packages.${system}.latest.withComponents [
      "cargo"
      "clippy"
      "llvm-tools-preview"
      "miri"
      "rustc"
      "rust-analyzer-preview"
      "rust-docs"
      "rust-src"
      "rust-std"
      "rustfmt"
    ];
    rust-analyzer = rust-toolchain;
    rust-analyzer-git = pkgs.callPackage ./rust-analyzer-git.nix { inherit importCargo rust-analyzer-src rust-toolchain; };
  }
else
  { }
