#!/bin/bash

set -eu

script="etc/os/ubuntu/opt/dashlane-cli.sh"

assert_contains() {
    local pattern="$1"

    if ! grep -Eq "$pattern" "$script"; then
        echo "missing expected pattern: $pattern" >&2
        exit 1
    fi
}

assert_not_contains() {
    local pattern="$1"

    if grep -Eq "$pattern" "$script"; then
        echo "unexpected pattern found: $pattern" >&2
        exit 1
    fi
}

assert_contains 'REAL_HOME="\$HOME"'
assert_contains 'brew_prefix="/home/linuxbrew/\.linuxbrew"'
assert_contains 'created_brew_prefix=0'
assert_contains 'created_brew_prefix=1'
assert_contains 'sudo rm -rf "\$brew_prefix"'
assert_contains 'mkdir -p .*"\$REAL_HOME/\.local/bin"'
assert_contains 'cp .*"\$REAL_HOME/\.local/bin/dcli"'
assert_contains 'ldd "\$REAL_HOME/\.local/bin/dcli"'

assert_not_contains 'command -v dashlane-cli'
assert_not_contains 'mktemp -d'
assert_not_contains '\.dashlane-cli'
assert_not_contains 'ln -s .*dcli'
assert_not_contains 'dashlane-cli.*ln -s|ln -s .*dashlane-cli'
