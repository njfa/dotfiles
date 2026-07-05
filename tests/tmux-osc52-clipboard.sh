#!/bin/bash

set -eu

tmux_conf="dot_config/tmux/tmux.conf"

assert_contains() {
    local file="$1"
    local pattern="$2"

    if ! grep -Eq "$pattern" "$file"; then
        echo "missing expected pattern in $file: $pattern" >&2
        exit 1
    fi
}

# ssh先のnvimが発行するOSC 52をtmuxが受け取り、バッファへ格納できること
assert_contains "$tmux_conf" 'set-option -s set-clipboard on'

# 外側端末のterminfoにMsが無い環境でもホスト側クリップボードへ転送できること
assert_contains "$tmux_conf" "set -as terminal-features ',\*:clipboard'"
