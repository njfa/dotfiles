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

assert_contains "$nvim_config" 'vim\.opt\.clipboard = "unnamed,unnamedplus"'
assert_contains "$nvim_config" 'vim\.opt\.clipboard = ""'
assert_contains "$nvim_config" 'vim\.api\.nvim_create_autocmd\("TextYankPost"'
assert_contains "$nvim_config" 'if vim\.v\.event\.operator ~= "y" then'
assert_contains "$nvim_config" 'osc52_copy\(vim\.v\.event\.regcontents, vim\.v\.event\.regtype\)'
assert_not_contains "$nvim_config" 'cache_enable ='
