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
    enableJupyter = mkEnableOption "Jupyter";
    enableNode = mkEnableOption "Node.js";
    enableRust = mkEnableOption "Rust";
    enableR = mkEnableOption "R";
    enableTypescript = mkEnableOption "Typescript";
    rPackages = mkOption {
      type = listOf package;
      default = [ ];
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
        pkgs.crate2nix
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

    (mkIf cfg.enableRust {
      environment.systemPackages = [
        self.packages.${system}.rust-toolchain
        self.packages.${system}.rust-analyzer
      ];
    })

    (mkIf cfg.enableR {
      environment.systemPackages = [
        (pkgs.rWrapper.override { packages = cfg.rPackages; })
        (pkgs.rstudioWrapper.override { packages = cfg.rPackages; })
      ];
    })

    (mkIf cfg.enableJupyter { })

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
