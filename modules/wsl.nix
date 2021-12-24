# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ nixos-wsl, ... }:
{ config, lib, pkgs, modulesPath, ... }:

with lib;

let
  cfg = config.braunse.wsl;
  mkWSLOverride = mkOverride 90;

  syschdemd = import "${nixos-wsl}/syschdemd.nix" {
    inherit config lib pkgs;
    inherit (cfg) defaultUser;
  };

  wslpath = pkgs.runCommandNoCC "wslpath" { } ''
    mkdir -p $out/bin
    ln -s /init $out/bin/wslpath
  '';
in
{
  options.braunse.wsl = with types; {
    enable = mkEnableOption "WSL support";

    defaultUser = mkOption {
      type = str;
      default = "nixos";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wsl-open
      pkgs.wslu
      wslpath
    ];

    systemd.services.wsl-mount-binfmt-misc = {
      path = [ pkgs.util-linux ];
      script = ''
        if [ ! -e /proc/sys/fs/binfmt_misc/status ]; then
          mount -t binfmt_misc binfmt_misc /proc/sys/fs/binfmt_misc
        fi
      '';
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        Restart = "no";
      };
    };

    boot.isContainer = mkWSLOverride true;
    boot.loader.grub.enable = mkWSLOverride false;
    boot.loader.systemd-boot.enable = mkWSLOverride false;

    environment.etc.hosts.enable = mkWSLOverride false;
    networking.dhcpcd.enable = mkWSLOverride false;
    networking.resolvconf.enable = mkWSLOverride false;

    users.users.${cfg.defaultUser} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    users.users.root = {
      shell = mkWSLOverride "${syschdemd}/bin/syschdemd";
      extraGroups = [ "root" ];
    };

    security.sudo.wheelNeedsPassword = false;

    systemd.services = {
      "serial-getty@ttyS0".enable = mkWSLOverride false;
      "serial-getty@hvc0".enable = mkWSLOverride false;
      "getty@tty1".enable = mkWSLOverride false;
      "autovt@".enable = mkWSLOverride false;
      firewall.enable = mkWSLOverride false;
      systemd-resolved.enable = mkWSLOverride false;
      resolvconf.enable = mkWSLOverride false;
      systemd-udevd.enable = mkWSLOverride false;
    };

    systemd.enableEmergencyMode = mkWSLOverride false;

    system.build.wslTarball =
      let
        prepareScript = pkgs.writeShellScriptBin "wsl-prepare" ''
          set -e

          mkdir -m0755 ./bin ./etc
          mkdir -m1777 ./tmp

          # Temporarily, NixOS's activate script will set the correct one
          ln -s ${config.users.users.root.shell} ./bin/sh

          # Need a /bin/mount
          ln -s /nix/var/nix/profiles/system/sw/bin/mount ./bin/mount

          # Set the profile
          system=${config.system.build.toplevel}
          ./$system/sw/bin/nix-store --store $(pwd) --load-db < ./nix-path-registration
          rm ./nix-path-registration
          ./$system/sw/bin/nix-env --store $(pwd) -p ./nix/var/nix/profiles/system --set $system

          touch ./etc/NixOS
        '';
      in
      pkgs.callPackage "${modulesPath}/../lib/make-system-tarball.nix" {
        contents = [ ];
        storeContents = [
          { object = config.system.build.toplevel; symlink = "none"; }
          { object = prepareScript; symlink = "none"; }
        ];
        extraCommands = ''
          ${prepareScript}/bin/wsl-prepare
        '';
        extraArgs = "--hard-dereference";
        compressCommand = "gzip";
        compressionExtension = ".gz";
      };

  };
}
#  input = {
#  sweet.com = ""(essen)";
#url = "/chestnut";
# /YAY/;
# YaY//////:
# AHIHI;
#}
