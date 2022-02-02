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
        default = false;
        description = "Whether to include my default set of utility programs";
      };

      unfree.allow = mkOption {
        type = listOf str;
        default = [ ];
        description = "What unfree packages to allow";
      };

      useMicrosoftFonts = mkOption {
        type = bool;
        default = false;
        description = "Allow installing Microsoft font packages";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        ripgrep
        fd
        bat
        lsd
        file
        p7zip
        ispell
      ];

      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) cfg.unfree.allow;
    }

    (mkIf cfg.useMicrosoftFonts {
      braunse.utils.unfree.allow = [ "corefonts" "vista-fonts" ];
      fonts.fonts = [
        pkgs.corefonts
        pkgs.vistafonts
      ];
    })
  ]);
}
