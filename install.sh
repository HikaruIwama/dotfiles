#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

mise=$HOME/.local/bin/mise
[[ -x $mise ]] || curl -fsSL https://mise.run | sh
"$mise" trust
"$mise" bootstrap --update
