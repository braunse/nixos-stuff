# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, nixpkgs, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    self.nixosModule

    ({ config, lib, pkgs, ... }: {
      braunse.wsl = {
        enable = true;
        defaultUser = "seb";
      };

      braunse.dev = {
        enable = true;
        enableElixir = true;
        enableRust = true;
        enableR = true;
        enableTypescript = true;

        rPackages = with pkgs.rPackages; [
          languageserver
          shiny
          tidyverse
        ];
      };

      braunse.xpra.enable = true;

      users.users.seb.xpraDisplay = ":101";

      networking.hostName = "nixos-wsl-amadeus";

      nix.package = pkgs.nixFlakes;
      nix.extraOptions = ''
        experimental-features = nix-command flakes
        keep-derivations = true
      '';

      nix.registry.nixpkgs.flake = nixpkgs;

      documentation = {
        enable = true;
        man.enable = true;
        nixos.enable = true;
      };
    })
  ];
}
