#!/bin/bash

set -eu

zshrc="dot_zshrc"
wrapper="bin/xdg-open"
installer="etc/os/ubuntu/init/xdg-open.sh"

assert_file_exists() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "missing expected file: $file" >&2
        exit 1
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"

    if ! grep -Eq "$pattern" "$file"; then
        echo "missing expected pattern in $file: $pattern" >&2
        exit 1
    fi
}

assert_file_exists "$wrapper"
assert_file_exists "$installer"

assert_contains "$zshrc" "export BROWSER='/mnt/c/Windows/System32/rundll32.exe url.dll,FileProtocolHandler'"
if grep -Eq 'browser\.sh' "$zshrc"; then
    echo "unexpected browser.sh reference in $zshrc" >&2
    exit 1
fi

if [ -e "bin/browser.sh" ]; then
    echo "unexpected legacy browser wrapper: bin/browser.sh" >&2
    exit 1
fi

assert_contains "$wrapper" '^#!/bin/sh$'
assert_contains "$wrapper" '/mnt/c/Windows/System32/rundll32\.exe url\.dll,FileProtocolHandler "\$@"'
assert_contains "$installer" 'sudo ln -sf "\$DOTFILES_PATH/bin/xdg-open" /usr/local/bin/xdg-open'
