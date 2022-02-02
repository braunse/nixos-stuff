# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, rust-overlay, ... }:
{ config, lib, pkgs, ... }:

with builtins;
with lib;

let
  cfg = config.braunse.dev;
  inherit (pkgs) system;
  emacs = pkgs.emacs.pkgs.withPackages (p:
    map (n: getAttr n p) cfg.emacsPackages
  );
in
{
  options.braunse.dev = with types; {
    enable = mkEnableOption "Development Environments";
    enableElixir = mkEnableOption "Elixir";
    enableFonts = mkEnableOption "Nerd Fonts";
    enableHaskell = mkEnableOption "Haskell";
    enableJava = mkEnableOption "Java";
    enableJupyter = mkEnableOption "Jupyter";
    enableNode = mkEnableOption "Node.js";
    enablePurescript = mkEnableOption "Purescript";
    enableRust = mkEnableOption "Rust";
    enableR = mkEnableOption "R";
    enableScala = mkEnableOption "Scala";
    enableTypescript = mkEnableOption "Typescript";
    enableLocalDevDns = mkEnableOption "Local Dev DNS";
    enableLocalDevNginx = mkEnableOption "Local Dev Nginx";
    jdk = mkOption {
      type = package;
      default = pkgs.jdk17;
    };
    nginx.localTld = mkOption {
      type = str;
      default = "l0";
    };
    nginx.namedServices = mkOption {
      type = attrsOf port;
      default = { };
    };
    rPackages = mkOption {
      type = listOf package;
      default = [ ];
    };
    ghcVersions = mkOption {
      type = listOf str;
      default = [ "8107" ];
    };
    nerdFonts = mkOption {
      type = listOf str;
      default = [
        "CascadiaCode"
        "FiraCode"
        "Hasklig"
        "Inconsolata"
        "Iosevka"
        "JetBrainsMono"
        "SourceCodePro"
        "Terminus"
      ];
    };
    emacsPackages = mkOption {
      type = listOf str;
      default = [
        "vterm"
      ];
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        git
        nixpkgs-fmt
        gcc
        ripgrep
        fd
        emacs
      ];
    }

    (mkIf cfg.enableElixir {
      environment.systemPackages = with pkgs.beam.packages.erlangR24; [
        erlang
        erlang-ls
        elixir_1_12
        elixir_ls
      ];
    })

    (mkIf cfg.enableJava {
      environment.systemPackages = with pkgs; [
        cfg.jdk
        (maven3.override { jdk = cfg.jdk; })
      ];
    })

    (mkIf cfg.enableNode {
      environment.systemPackages = with pkgs; with pkgs.nodePackages; [
        nodejs
        yarn
        pnpm
        node2nix
      ];
    })

    (mkIf cfg.enableHaskell {
      environment.systemPackages =
        map (v: pkgs.haskell.compiler."ghc${v}") cfg.ghcVersions ++
        [
          (pkgs.haskell-language-server.override { supportedGhcVersions = cfg.ghcVersions; })
          pkgs.cabal-install
          pkgs.cabal2nix
        ];
    })

    (mkIf cfg.enableLocalDevDns {
      services.unbound = {
        enable = true;
        settings = {
          server = {
            domain-insecure = [ "${cfg.nginx.localTld}." ];
            local-zone = [ "${cfg.nginx.localTld}. nodefault" ];
            do-not-query-localhost = "no";
          };
          stub-zone = [
            {
              name = "${cfg.nginx.localTld}.";
              stub-addr = "127.0.0.1@1053";
            }
          ];
        };
      };

      services.nsd = {
        enable = true;
        interfaces = [ "127.0.0.1@1053" "::1@1053" ];
        zones = {
          "${cfg.nginx.localTld}." = {
            data = ''
              $ORIGIN ${cfg.nginx.localTld}.
              $TTL 300
              @ IN SOA ns.${cfg.nginx.localTld}. admin.ns.${cfg.nginx.localTld}. 127001001 300 300 1200 300
              @ IN NS 127.0.0.1
              *.${cfg.nginx.localTld}. IN A 127.0.0.1
            '';
          };
        };
      };
    })

    (mkIf cfg.enableLocalDevNginx {
      services.nginx = {
        enable = true;
        virtualHosts."__catchall" = {
          serverName = "~^(?<dev_name>[A-za-z0-9-]+)-(?<dev_port>[0-9]+)[.]${cfg.nginx.localTld}$";
          locations."/" = {
            extraConfig = ''
              proxy_pass http://127.0.0.1:$dev_port;
              proxy_set_header Host $host;
            '';
          };
        };
      };
    })

    (mkIf cfg.enableRust {
      environment.systemPackages = [
        self.packages.${system}.rust-toolchain
        pkgs.crate2nix

        pkgs.cargo-about
        pkgs.cargo-crev
        pkgs.cargo-deny
        pkgs.cargo-edit
        pkgs.cargo-feature
        pkgs.cargo-udeps
        pkgs.cargo-whatfeatures
      ];
    })

    (mkIf cfg.enableR {
      environment.systemPackages = [
        (pkgs.rWrapper.override { packages = cfg.rPackages; })
        (pkgs.rstudioWrapper.override { packages = cfg.rPackages; })
      ];
    })

    (mkIf cfg.enableJupyter { })

    (mkIf cfg.enablePurescript {
      environment.systemPackages = [
        pkgs.purescript
        pkgs.purescript-psa
        pkgs.psc-package
        pkgs.pscid
        pkgs.pulp
      ];
    })

    (mkIf cfg.enableScala {
      environment.systemPackages = [
        pkgs.dotty
        pkgs.scala
        pkgs.metals
        pkgs.mill
        pkgs.sbt
      ];
    })

    (mkIf cfg.enableTypescript {
      environment.systemPackages = [
        pkgs.nodejs
        pkgs.deno
        pkgs.nodePackages.typescript-language-server
      ];
    })

    (mkIf cfg.enableFonts {
      fonts.fonts = [
        (pkgs.nerdfonts.override {
          fonts = cfg.nerdFonts;
        })
      ];
    })
  ]);
}
