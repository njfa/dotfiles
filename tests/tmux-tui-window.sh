#!/bin/bash

set -eu

tmux_conf="dot_config/tmux/tmux.conf"
tmuxpopup="bin/tmuxpopup"

assert_contains() {
    local file="$1"
    local pattern="$2"

    if ! grep -Eq -- "$pattern" "$file"; then
        echo "missing expected pattern in $file: $pattern" >&2
        exit 1
    fi
}

assert_not_contains() {
    local file="$1"
    local pattern="$2"

    if grep -Eq -- "$pattern" "$file"; then
        echo "unexpected pattern found in $file: $pattern" >&2
        exit 1
    fi
}

assert_not_exists() {
    local file="$1"

    if [ -e "$file" ]; then
        echo "unexpected file exists: $file" >&2
        exit 1
    fi
}

assert_not_exists "$tmuxpopup"
assert_not_contains "$tmux_conf" 'tmuxpopup shell'
assert_not_contains "$tmux_conf" 'tmuxpopup lazygit|tmuxpopup lazydocker|tmuxpopup yazi|display-popup.*lazygit|display-popup.*lazydocker'
assert_contains "$tmux_conf" 'bind -n M-g new-window -c "#\{pane_current_path\}" lazygit'
assert_contains "$tmux_conf" 'bind -n M-d new-window -c "#\{pane_current_path\}" lazydocker'
assert_contains "$tmux_conf" 'bind -n M-s new-window -c "#\{pane_current_path\}" .tmux set -p allow-passthrough on; exec yazi.'
