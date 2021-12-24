# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ ... }:
{ config, lib, pkgs, ... }:

with lib;

let cfg = config.braunse.xpra;
in
{
  options = with types;{
    braunse.xpra = {
      enable = mkEnableOption "Xpra support";
    };

    users.users = mkOption {
      type = attrsOf (submodule {
        options = {
          xpraDisplay = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.etc = listToAttrs (
        concatMap
          (user:
            let inherit (config.users.users.${user}) xpraDisplay; in
            if xpraDisplay != null then [{
              name = "xpra-assigned-displays/${user}";
              value = {
                text = xpraDisplay;
                mode = "0400";
                user = user;
              };
            }] else [ ])
          (attrNames config.users.users)
      );

      systemd.user.services.xpra = {
        enable = true;
        wantedBy = [ "default.target" ];
        unitConfig = {
          ConditionFileNotEmpty = "/etc/xpra-assigned-displays/%u";
        };
        serviceConfig = {
          Type = "forking";
          PIDFile = "/run/xpra-%U.pid";
        };
        path = [ pkgs.xpra ];
        script = ''
          xpra start $(cat /etc/xpra-assigned-displays/%u) --systemd-run=no --daemon=no --pidfile=/run/xpra-%U.pid
        '';
      };

      environment.extraInit = ''
        if [ -r "/etc/xpra-assigned-displays/$USER" ]; then
          export DISPLAY="`cat /etc/xpra-assigned-displays/$USER`"
        fi
      '';
    }
  ]);
}
