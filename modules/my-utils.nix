{ ... }:
{ config, lib, pkgs, ... }:

with builtins;
with lib;

let
  cfg = config.braunse.utils;

in
{
  options = with types; {
    braunse.utils = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Whether to include my default set of utility programs";
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        ripgrep
        fd
        bat
        lsd
        file
        p7zip
      ];
    })
  ];
}
