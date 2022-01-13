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
      braunse.dev = {
        enable = true;
        enableElixir = true;
        enableFonts = true;
        enableNode = true;
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

      braunse.utils = {
        enable = true;
        useMicrosoftFonts = true;
      };

      users.users.seb = {
        isNormalUser = true;
        xpraDisplay = ":101";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdIT0XF1FMQTSBfm5kkyNT7qPxzMtAsbCTCFmyHBWaS" ];
        extraGroups = [ "wheel" "docker" ];
      };

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.initrd.availableKernelModules = [ "sd_mod" "sr_mod" ];
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
      fileSystems."/boot" = {
        device = "/dev/disk/by-label/BOOT";
        fsType = "vfat";
      };
      swapDevices = [
        { device = "/dev/disk/by-label/swap"; }
      ];

      virtualisation.hypervGuest.enable = true;

      networking.hostName = "nixos-dev1";

      networking.interfaces.eth0.useDHCP = true;

      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 ];

      networking.extraHosts = ''
      '';

      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "de-latin1";

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = with pkgs; [
        docker-compose
        python3
      ];

      services.openssh = {
        enable = true;
        forwardX11 = true;
      };

      services.x2goserver.enable = true;
      services.xserver.desktopManager = {
        xfce.enable = true;
      };

      services.postgresql = {
        enable = true;
        enableTCPIP = true;
      };

      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
        autoPrune.enable = true;
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
            bashrcExtra = ''
              [ -d "$HOME/.global_node_modules/bin" ] && PATH="$HOME/.global_node_modules/bin''${PATH:+:$PATH}"
            '';
            historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
          };

          programs.bat.enable = true;

          programs.direnv = {
            enable = true;
          };

          programs.firefox = {
            enable = true;
          };

          programs.git = {
            enable = true;
            userName = "Sebastien Braun";
            userEmail = "sebastien@sebbraun.de";
          };

          programs.htop.enable = true;

          programs.lsd.enable = true;

          programs.keychain = {
            enable = true;
            agents = [ "ssh" ];
            keys = [ "id_ed25519_2" ];
          };

          programs.tmux = {
            enable = true;
          };
        };
      };

      system.stateVersion = "21.11";
    })
  ];
}
