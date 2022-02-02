# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{
  description = "NixOS modules I use";

  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-cargo = {
      url = "github:edolstra/import-cargo";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixos-wsl = {
      url = "github:braunse/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    rust-analyzer-src = {
      url = "github:rust-analyzer/rust-analyzer";
      flake = false;
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    struct = {
      url = "github:braunse/nix-flake-structure";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, struct, ... }@inputs: {
    devShell = struct.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in
      pkgs.mkShell {
        name = "braunse-nixos-modules-shell";
        buildInputs = with pkgs; [
          nixpkgs-fmt
          reuse
        ];
      });

    nixosModules = struct.lib.importDirectory { path = "${self}/modules"; args = inputs; };
    nixosModule = self.nixosModules.default;

    nixosConfigurations = struct.lib.importDirectory { path = "${self}/systems"; args = inputs; };

    packages = struct.lib.mergeDirectory {
      path = "${self}/packages";
      systems = struct.lib.defaultSystems;
      args = system: inputs // { pkgs = nixpkgs.legacyPackages.${system}; inherit system; };
      filter = struct.lib.filters.compatible;
    };

    checks = struct.lib.importDirectoryPackages {
      path = "${self}/checks";
      systems = struct.lib.defaultSystems;
      inherit nixpkgs;
    };
  };
}
