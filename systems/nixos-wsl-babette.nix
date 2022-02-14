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
        wslConf.enable = true;
      };

      braunse.dev = {
        enable = true;
        enableElixir = true;
        enableFonts = true;
        enableHaskell = true;
        enableJava = true;
        enableLocalDevDns = true;
        enableLocalDevNginx = true;
        enableNode = true;
        enablePurescript = true;
        enableRust = true;
        enableR = true;
        enableScala = true;
        enableTypescript = true;

        nginx.localTld = "l1";

        rPackages = with pkgs.rPackages; [
          languageserver
          shiny
          tidyverse
        ];

        vscode.enableGeneralTools = true;
      };

      braunse.utils = {
        enable = true;
        useMicrosoftFonts = true;
        unfree.allow = ["idea-ultimate"]; 
      };

      braunse.xpra.enable = true;

      users.users.seb = {
        isNormalUser = true;
        xpraDisplay = ":101";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdIT0XF1FMQTSBfm5kkyNT7qPxzMtAsbCTCFmyHBWaS" ];
        extraGroups = [ "wheel" "docker" "podman" ];
        packages = [
          pkgs.kube3d
        ];
      };

      networking.hostName = "nixos-wsl-babette";

      services.openssh = {
        enable = true;
        listenAddresses = [{ addr = "127.0.0.1"; port = 17022; } { addr = "0.0.0.0"; port = 22; }];
        forwardX11 = true;
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
      nix.buildMachines = [
        {
          hostName = "builder1";
          maxJobs = 4;
          speedFactor = 1;
          sshKey = "/root/.ssh/nixos-dev1-builder";
          sshUser = "nix-ssh";
          supportedFeatures = ["kvm" "big-parallel"];
          systems = [ "x86_64-linux" ];
        }
      ];

      documentation = {
        enable = true;
        man.enable = true;
        nixos.enable = true;
      };

      services.nginx = {
        enable = true;
        virtualHosts = {
          "kc-7f000002.nip.io" = {
            locations."/" = {
              proxyPass = "http://localhost:8090";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_buffer_size 16k;
                proxy_buffers 8 16k;
              '';
            };
          };
          "isgfui-7f000002.nip.io" = {
            locations."/" = {
              proxyPass = "http://localhost:3000";
              extraConfig = ''
                proxy_set_header Host $host;
              '';
            };
          };
          "isgfbe-7f000002.nip.io" = {
            locations."/".proxyPass = "http://localhost:8055";
          };
          "isgfau-7f000002.nip.io" = {
            locations."/".proxyPass = "http://localhost:3001";
          };
        };
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
        enable = false;
        enableOnBoot = true;
        autoPrune.enable = true;
      };

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.seb = let sconfig = config; in { config, lib, pkgs, ... }: {
          home.file.".tools/java".source = sconfig.braunse.dev.jdk;

          programs.bash = {
            enable = true;
            enableVteIntegration = true;
            historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
            bashrcExtra = ''
              [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
            '';
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

          programs.lsd.enable = true;

          programs.keychain = {
            enable = true;
            agents = [ "ssh" ];
            keys = [ "id_ed25519_2" ];
            extraFlags = ["--systemd"];
          };

          programs.tmux = {
            enable = true;
          };

          programs.vscode = {
            enable = true;
            package = pkgs.vscodium-fhs;
            extensions = sconfig.braunse.dev.vscode.extensions;
          };
        };
      };
    })
  ];
}
