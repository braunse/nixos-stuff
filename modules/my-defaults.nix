{ ... }:
{ config, lib, pkgs, ... }:

with builtins;
with lib;

let
  cfg = config.braunse.defaults;

in
{
  options = with types; {
    braunse.defaults = {
      enable = mkOption {
        type = bool;
        default = false;
        description = "Whether to include my default settings";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      nix.autoOptimiseStore = true;
    }
  ]);
}
