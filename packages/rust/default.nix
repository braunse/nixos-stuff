# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ import-cargo, rust-overlay, rust-analyzer-src, pkgs, system, ... }:
let
  importCargo = import-cargo.builders.importCargo;
in
if rust-overlay.packages ? "${system}" then
  {
    rust-toolchain = rust-overlay.packages.${system}.rust-latest;
    rust-analyzer-git = pkgs.callPackage ./rust-analyzer-git.nix { inherit importCargo rust-analyzer-src; };
  }
else
  { }
