#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
target="$tmp/custom checkout"
mkdir -p "$target/bin" "$target/dot_config/mise" "$tmp/home/.config/dotfiles" "$tmp/tools"
cp "$repo_root/bin/de" "$target/bin/de"
cp "$repo_root/dot_config/mise/config.toml" "$target/dot_config/mise/config.toml"
ln -s "$target/bin" "$tmp/home/.config/dotfiles/bin"
cat > "$tmp/tools/mise" <<'STUB'
#!/usr/bin/env bash
if [[ $1 == activate ]]; then exit 0; fi
test -f "$MISE_CONFIG_FILE"
printf '%s\n' "$DOTFILES_PATH"
STUB
chmod +x "$tmp/tools/mise"
output=$(HOME="$tmp/home" PATH="$tmp/tools:$PATH" "$tmp/home/.config/dotfiles/bin/de" m --version)
[[ $output == "$target" ]]
