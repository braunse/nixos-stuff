# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ self, ... }:
{ config, lib, pkgs, ... }:

{
  imports = [
    self.nixosModules.wsl
    self.nixosModules.dev-envs
    self.nixosModules.xpra
    self.nixosModules.my-utils
  ];
}
