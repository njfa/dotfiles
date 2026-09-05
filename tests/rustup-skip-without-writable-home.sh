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

# Run the task body directly so this test does not depend on a mise installation.
task=$(python3 - "$repo_root/dot_config/mise/config.toml" <<'PY'
import sys
text = open(sys.argv[1]).read().split('[tasks.rustup]', 1)[1].split("'''", 2)[1]
assert text.startswith("bash -lc '") and text.rstrip().endswith("'")
print(text[len("bash -lc '"):].rstrip()[:-1])
PY
)
if [[ $UID -eq 0 ]]; then
  echo 'SKIP: writable-directory checks require a non-root user'
  exit 0
fi
output=$(
  PATH="$tools_dir:/usr/bin:/bin" \
    RUSTUP_HOME="$readonly_dir/rustup" \
    CARGO_HOME="$readonly_dir/cargo" \
    /bin/bash -c "$task" 2>&1
)

if [[ "$output" != *'Skipping rustup: RUSTUP_HOME or CARGO_HOME is not writable.'* ]]; then
  printf 'FAIL: expected rustup skip message, got:\n%s\n' "$output" >&2
  exit 1
fi
