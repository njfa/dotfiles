#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="$repo_root/dot_config/mise/config.toml"

if ! grep -qx 'neovim = "0.12"' "$config"; then
  printf 'FAIL: expected neovim = "0.12" in %s\n' "$config" >&2
  exit 1
fi

if ! grep -Fq 'git config --global wt.basedir \".worktrees\"' "$config"; then
  printf 'FAIL: expected wt.basedir to use .worktrees in %s\n' "$config" >&2
  exit 1
fi

if grep -qx '\[tasks\.sync\]' "$config"; then
  printf 'FAIL: expected ambiguous sync task to be removed from %s\n' "$config" >&2
  exit 1
fi

if ! grep -qx '\[tasks\.sync-to-windows\]' "$config"; then
  printf 'FAIL: expected sync-to-windows task in %s\n' "$config" >&2
  exit 1
fi

os_dependencies_task=$(awk '/^\[tasks\.os-dependencies\]/{f=1; next} /^\[/{f=0} f' "$config")
if [[ "$os_dependencies_task" != *'quiet = true'* ]]; then
  printf 'FAIL: expected os-dependencies task to suppress verbose command output in %s\n' "$config" >&2
  exit 1
fi
if [[ "$os_dependencies_task" == *"run = '''"* ]]; then
  printf 'FAIL: expected os-dependencies task command to avoid partial multiline mise output in %s\n' "$config" >&2
  exit 1
fi

required_init_tasks=(
  tpm
  mdformat
  git-wt
  zsh
  tmux
  sdkman
  connect
  xdg-open
  win32yank
  docker
)

for task in "${required_init_tasks[@]}"; do
  if ! grep -qx "\[tasks\.$task\]" "$config"; then
    printf 'FAIL: expected %s task in %s\n' "$task" "$config" >&2
    exit 1
  fi
  if ! grep -q "bash etc/os/ubuntu/init/$task.sh" "$config"; then
    printf 'FAIL: expected %s task to run its init script in %s\n' "$task" "$config" >&2
    exit 1
  fi
  if ! grep -qx "  \"mise run $task\"," "$config" && ! grep -qx "  \"mise run $task\"" "$config"; then
    printf 'FAIL: expected default task to run %s in %s\n' "$task" "$config" >&2
    exit 1
  fi
done

if grep -q 'DOTFILES_PATH/.env\|/\.env"\|/\.env ' "$config"; then
  printf 'FAIL: expected mise config not to depend on .env in %s\n' "$config" >&2
  exit 1
fi

if ! awk '/^\[tasks\.git-wt\]/{f=1; next} /^\[/{f=0} f' "$config" | grep -q 'GIT_WT_VERSION=v0.17.0'; then
  printf 'FAIL: expected git-wt task to define GIT_WT_VERSION in %s\n' "$config" >&2
  exit 1
fi

if ! awk '/^\[tasks\.tmux\]/{f=1; next} /^\[/{f=0} f' "$config" | grep -q 'TMUX_VERSION=3.6a'; then
  printf 'FAIL: expected tmux task to define TMUX_VERSION in %s\n' "$config" >&2
  exit 1
fi

if grep -q '\.claude\.json' "$config"; then
  printf 'FAIL: expected deploy task not to create .claude.json in %s\n' "$config" >&2
  exit 1
fi

if grep -qx 'opencode = "latest"' "$config" || grep -qx '\[tasks\.opencode\]' "$config"; then
  printf 'FAIL: expected opencode not to be managed in %s\n' "$config" >&2
  exit 1
fi

for tool in 'postgres = ' 'mysql = ' 'mysql-client = '; do
  if grep -q "$tool" "$config"; then
    printf 'FAIL: expected database clients not to be global tools in %s\n' "$config" >&2
    exit 1
  fi
done

if ! grep -qx '\[tasks\.psql\]' "$config" || ! grep -q 'apt-get install -y postgresql-client' "$config"; then
  printf 'FAIL: expected psql task to install postgresql-client via apt in %s\n' "$config" >&2
  exit 1
fi

if ! grep -qx '\[tasks\.mysql\]' "$config" || ! grep -q 'apt-get install -y mysql-client' "$config"; then
  printf 'FAIL: expected mysql task to install mysql-client via apt in %s\n' "$config" >&2
  exit 1
fi
