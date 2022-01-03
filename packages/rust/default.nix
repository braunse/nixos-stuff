# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ import-cargo, fenix, rust-analyzer-src, pkgs, system, ... }:
let
  importCargo = import-cargo.builders.importCargo;
in
if fenix.packages ? "${system}" then
  rec {
    rust-toolchain = fenix.packages.${system}.stable.withComponents [
      "cargo"
      "clippy"
      "llvm-tools-preview"
      "rustc"
      "rust-docs"
      "rust-src"
      "rust-std"
    ];
    rust-analyzer = fenix.packages.${system}.rust-analyzer;
    rust-analyzer-git = pkgs.callPackage ./rust-analyzer-git.nix { inherit importCargo rust-analyzer-src rust-toolchain; };
  }
else
  { }
