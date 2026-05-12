#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ignore_file="$repo_root/.chezmoiignore"

legacy_allow_patterns=(
  '!dot_bashrc'
  '!dot_zshrc'
  '!dot_p10k\.zsh'
  '!dot_ruff\.toml'
  '!dot_zsh/'
  '!dot_config/'
)

for pattern in "${legacy_allow_patterns[@]}"; do
  if grep -Eq "^${pattern}" "$ignore_file"; then
    printf 'FAIL: expected legacy allow pattern to be removed from %s: %s\n' "$ignore_file" "$pattern" >&2
    exit 1
  fi
done

required_patterns=(
  '!\.bashrc'
  '!\.zshrc'
  '!\.p10k\.zsh'
  '!\.ruff\.toml'
  '!\.zsh/'
  '!\.config/'
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -Eq "^${pattern}" "$ignore_file"; then
    printf 'FAIL: expected chezmoi allow pattern in %s: %s\n' "$ignore_file" "$pattern" >&2
    exit 1
  fi
done
