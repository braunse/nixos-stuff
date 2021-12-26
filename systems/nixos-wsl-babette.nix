# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, nixpkgs, home-manager, ... }:

nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    self.nixosModule
    home-manager.nixosModules.home-manager

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

      networking.hostName = "nixos-wsl-babette";

      services.openssh = {
        enable = true;
        listenAddresses = [{ addr = "127.0.0.1"; port = 17022; } { addr = "0.0.0.0"; port = 22; }];
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

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.seb = { config, lib, pkgs, ... }: {
          programs.bash = {
            enable = true;
            enableVteIntegration = true;
            historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
          };

          programs.bat.enable = true;

          programs.direnv = {
            enable = true;
          };

          programs.git = {
            enable = true;
            userName = "Sebastien Braun";
            userEmail = "sebastien@sebbraun.de";
          };

          programs.lsd.enable = true;

          programs.keychain = {
            enable = true;
            agents = [ "ssh" ];
            keys = [ "id_ed25519_2" ];
          };
        };
      };
    })
  ];
}
