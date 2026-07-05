#!/bin/bash

set -eu

nvim_config="dot_config/nvim/init.lua"

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

# ヤンク・削除が常にclipboardプロバイダを経由してOSC 52で送信されること
assert_contains "$nvim_config" 'vim\.opt\.clipboard = "unnamed,unnamedplus"'
assert_contains "$nvim_config" 'osc52\.copy\("\+"\)'
assert_contains "$nvim_config" 'osc52\.copy\("\*"\)'

# 貼り付けはOSC 52クエリではなくnvim内部レジスタから行うこと
assert_contains "$nvim_config" "paste_from_register\('\"'\)"
assert_not_contains "$nvim_config" 'osc52\.paste'

# eb84959のautocmdベースの設計が残っていないこと
assert_not_contains "$nvim_config" 'TextYankPost'
assert_not_contains "$nvim_config" 'vim\.opt\.clipboard = ""'

# 正しいオプション名はcache_enabled
assert_not_contains "$nvim_config" 'cache_enable ='
