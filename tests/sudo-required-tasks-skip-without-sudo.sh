#!/usr/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

tools_dir="$tmp_dir/tools"
mkdir -p "$tools_dir"

cat >"$tools_dir/id" <<'STUB'
#!/usr/bin/bash
set -euo pipefail
if [[ ${1:-} == '-u' ]]; then
  printf '1000\n'
fi
STUB
chmod +x "$tools_dir/id"

cat >"$tools_dir/command" <<'STUB'
#!/usr/bin/bash
set -euo pipefail
if [[ ${1:-} == '-v' && ${2:-} == 'sudo' ]]; then
  exit 1
fi
exec /usr/bin/command "$@"
STUB
chmod +x "$tools_dir/command"

cat >"$tools_dir/grep" <<'STUB'
#!/usr/bin/bash
set -euo pipefail
if [[ ${1:-} == '-qi' && ${2:-} == 'microsoft' && ${3:-} == '/proc/version' ]]; then
  exit 0
fi
exec /usr/bin/grep "$@"
STUB
chmod +x "$tools_dir/grep"

scripts=(
  etc/os/ubuntu/init/tpm.sh
  etc/os/ubuntu/init/git-wt.sh
  etc/os/ubuntu/init/zsh.sh
  etc/os/ubuntu/init/tmux.sh
  etc/os/ubuntu/init/sdkman.sh
  etc/os/ubuntu/init/connect.sh
  etc/os/ubuntu/init/xdg-open.sh
  etc/os/ubuntu/init/docker.sh
)

for script in "${scripts[@]}"; do
  output=$(PATH="$tools_dir" DOTFILES_PATH="$repo_root" GIT_WT_VERSION=v0.17.0 TMUX_VERSION=3.6a /usr/bin/bash "$repo_root/$script" 2>&1 || true)
  if [[ "$output" != *'sudo is unavailable and current user is not root'* ]]; then
    printf 'FAIL: expected sudo skip message for %s, got:\n%s\n' "$script" "$output" >&2
    exit 1
  fi
done
