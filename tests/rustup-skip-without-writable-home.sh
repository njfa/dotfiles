#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

tools_dir="$tmp_dir/tools"
readonly_dir="$tmp_dir/readonly"
mkdir -p "$tools_dir" "$readonly_dir"
chmod 555 "$readonly_dir"

cat >"$tools_dir/curl" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'FAIL: curl should not be called when rustup home is not writable\n' >&2
exit 1
STUB
chmod +x "$tools_dir/curl"

output=$(
  PATH="$tools_dir:/usr/bin:/bin" \
    RUSTUP_HOME="$readonly_dir/rustup" \
    CARGO_HOME="$readonly_dir/cargo" \
    MISE_CONFIG_FILE="$repo_root/dot_config/mise/config.toml" \
    mise run rustup 2>&1
)

if [[ "$output" != *'Skipping rustup: RUSTUP_HOME or CARGO_HOME is not writable.'* ]]; then
  printf 'FAIL: expected rustup skip message, got:\n%s\n' "$output" >&2
  exit 1
fi
