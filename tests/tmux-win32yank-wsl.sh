#!/bin/bash

set -eu

tmux_installer="etc/os/ubuntu/init/tmux.sh"
win32yank_installer="etc/os/ubuntu/init/win32yank.sh"
tmux_conf="dot_config/tmux/tmux.conf"
tmux_copy="bin/tmux-copy"
lazygit_config="dot_config/lazygit/config.yml"

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

assert_not_contains "$tmux_conf" 'copy-pipe "win32yank\.exe -i --crlf"'
assert_not_contains "$tmux_conf" 'copy-pipe-and-cancel "win32yank\.exe -i --crlf"'
assert_contains "$tmux_conf" 'bind -T copy-mode-vi y send -X copy-pipe "\$HOME/\.dotfiles/bin/tmux-copy"'
assert_contains "$tmux_conf" 'bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel "\$HOME/\.dotfiles/bin/tmux-copy"'

assert_contains "$tmux_copy" 'win32yank\.exe -i --crlf'
assert_contains "$tmux_copy" 'base64'
assert_contains "$tmux_copy" '52;c;'

assert_not_contains "$lazygit_config" 'copyToClipboardCmd: .*win32yank\.exe -i --crlf'
assert_contains "$lazygit_config" 'copyToClipboardCmd: '\''echo \{\{text\}\} \| \$HOME/\.dotfiles/bin/tmux-copy'\'''
