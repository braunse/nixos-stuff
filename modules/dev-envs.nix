# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, rust-overlay, ... }:
{ config, lib, pkgs, ... }:

with lib;

let cfg = config.braunse.dev;
  inherit (pkgs) system;
in
{
  options.braunse.dev = with types; {
    enable = mkEnableOption "Development Environments";
    enableElixir = mkEnableOption "Elixir";
    enableJupyter = mkEnableOption "Jupyter";
    enableRust = mkEnableOption "Rust";
    enableR = mkEnableOption "R";
    enableTypescript = mkEnableOption "Typescript";
    rPackages = mkOption {
      type = listOf package;
      default = [ ];
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

    (mkIf cfg.enableRust {
      environment.systemPackages = [
        self.packages.${system}.rust-toolchain
        (self.packages.${system}.rust-analyzer-git.override { rustc = self.packages.${system}.rust-toolchain; cargo = self.packages.${system}.rust-toolchain; })
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
  ]);
}
