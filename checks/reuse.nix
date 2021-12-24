# Copyright (C) 2021  Sebastien Braun <sebastien@sebbraun.de>
#
# SPDX-License-Identifier: MPL-2.0

{ runCommandNoCC, reuse }:

runCommandNoCC "check-reuse-lint"
{
  buildInputs = [ reuse ];
} ''
  cd ${../.}
  reuse lint
  touch $out
''
