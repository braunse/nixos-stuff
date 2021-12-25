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
        enableFonts = true;
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

      users.users.seb = {
        xpraDisplay = ":101";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdIT0XF1FMQTSBfm5kkyNT7qPxzMtAsbCTCFmyHBWaS" ];
      };

      networking.hostName = "nixos-wsl-amadeus";

      services.openssh = {
        enable = true;
        listenAddresses = [{ addr = "127.0.0.1"; port = 17022; }];
      };

      nix.package = pkgs.nixFlakes;
      nix.extraOptions = ''
        experimental-features = nix-command flakes
        keep-derivations = true
      '';
      nix.nixPath = [
        "nixpkgs=${nixpkgs}"
      ];

      nix.registry.nixpkgs.flake = nixpkgs;

      documentation = {
        enable = true;
        man.enable = true;
        nixos.enable = true;
      };
    })
  ];
}
