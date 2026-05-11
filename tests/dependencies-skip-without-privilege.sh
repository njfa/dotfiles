#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

tools_dir="$tmp_dir/tools"
mkdir -p "$tools_dir"

cat >"$tools_dir/id" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == '-u' ]]; then
  printf '1000\n'
fi
STUB
chmod +x "$tools_dir/id"

if [[ $UID -eq 0 ]]; then
  if command -v runuser >/dev/null 2>&1 && id nobody >/dev/null 2>&1; then
    output=$(runuser -u nobody -- env PATH="$tools_dir" /usr/bin/bash "$repo_root/etc/os/ubuntu/init/dependencies.sh" 2>&1)
  else
    printf 'SKIP: non-root user execution is unavailable\n'
    exit 0
  fi
else
  output=$(PATH="$tools_dir" /usr/bin/bash "$repo_root/etc/os/ubuntu/init/dependencies.sh" 2>&1)
fi

if [[ "$output" != *'Skipping OS dependencies: sudo is unavailable and current user is not root.'* ]]; then
  printf 'FAIL: expected skip message, got:\n%s\n' "$output" >&2
  exit 1
fi
