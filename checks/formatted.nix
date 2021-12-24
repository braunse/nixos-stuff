# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ runCommandNoCC, nixpkgs-fmt }:

runCommandNoCC "check-nixpkgs-fmt"
{
  buildInputs = [ nixpkgs-fmt ];
} ''
  nixpkgs-fmt --check ${../.}
  touch $out
''
