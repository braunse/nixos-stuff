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
    jdk = mkOption {
      type = package;
      default = pkgs.jdk17;
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

    (mkIf cfg.enableRust {
      environment.systemPackages = [
        self.packages.${system}.rust-toolchain
        self.packages.${system}.rust-analyzer
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
