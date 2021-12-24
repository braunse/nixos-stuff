# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ pkgs
, stdenv
, rustc
, cargo
, importCargo
, rust-analyzer-src
}:
stdenv.mkDerivation {
  pname = "rust-analyzer-git";
  version = rust-analyzer-src.rev;
  src = rust-analyzer-src;
  nativeBuildInputs = [
    (importCargo { lockFile = "${rust-analyzer-src}/Cargo.lock"; inherit pkgs; }).cargoHome
    rustc
    cargo
  ];

  buildPhase = ''
    cd crates/rust-analyzer
    cargo build --release
  '';

  installPhase = ''
    install -Dm755 ../../target/release/rust-analyzer $out/bin/rust-analyzer
  '';

  meta.mainProgram = "rust-analyzer";
}
