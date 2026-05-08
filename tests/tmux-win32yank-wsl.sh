#!/bin/bash

set -eu

tmux_installer="etc/os/ubuntu/init/tmux.sh"
win32yank_installer="etc/os/ubuntu/init/win32yank.sh"
tmux_conf=".config/tmux/tmux.conf"

assert_contains() {
    local file="$1"
    local pattern="$2"

    if ! grep -Eq "$pattern" "$file"; then
        echo "missing expected pattern in $file: $pattern" >&2
        exit 1
    fi
}

assert_not_contains() {
    local file="$1"
    local pattern="$2"

    if grep -Eq "$pattern" "$file"; then
        echo "unexpected pattern found in $file: $pattern" >&2
        exit 1
    fi
}

assert_contains "$win32yank_installer" 'is_wsl\(\)'
assert_contains "$win32yank_installer" 'grep -qiE .*/proc/version'
assert_contains "$win32yank_installer" 'if ! is_wsl; then'
assert_contains "$win32yank_installer" 'if command -v win32yank\.exe >/dev/null 2>&1; then'
assert_contains "$win32yank_installer" 'windows_bin_dir="\$\(wslpath -u "\$USERPROFILE/bin"\)"'
assert_contains "$win32yank_installer" 'mkdir -p "\$windows_bin_dir"'
assert_not_contains "$tmux_installer" 'win32yank'

assert_contains "$tmux_conf" 'if-shell .command -v win32yank\.exe >/dev/null 2>&1 && \{ test -n "\$WSL_DISTRO_NAME" \|\| grep -qiE .*/proc/version 2>/dev/null; \}.'
assert_contains "$tmux_conf" 'bind -T copy-mode-vi y send -X copy-pipe "win32yank\.exe -i --crlf"'
assert_contains "$tmux_conf" 'bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel "win32yank\.exe -i --crlf"'
