#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="$repo_root/dot_config/mise/config.toml"

if ! grep -qx 'neovim = "0.12"' "$config"; then
  printf 'FAIL: expected neovim = "0.12" in %s\n' "$config" >&2
  exit 1
fi
