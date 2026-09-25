$ErrorActionPreference = 'Stop'

$DOTBOT_VERSION = '1.24.1'
$CONFIG = 'install.conf.yaml'

uvx --from "dotbot==$DOTBOT_VERSION" dotbot -d $PSScriptRoot -c (Join-Path $PSScriptRoot $CONFIG) @args
exit $LASTEXITCODE
