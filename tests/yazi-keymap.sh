#!/bin/bash

set -eu

keymap="dot_config/yazi/keymap.toml"

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

assert_not_contains() {
	local file="$1"
	local pattern="$2"

	if grep -Eq "$pattern" "$file"; then
		echo "unexpected pattern found in $file: $pattern" >&2
		exit 1
	fi
}

assert_file_exists "$keymap"
assert_contains "$keymap" 'on = "<C-r>", run = "plugin fzf"'
assert_contains "$keymap" 'on = "<C-f>", run = "plugin zoxide"'
assert_contains "$keymap" 'on = "m", run = .*shell -- zoxide add "\$PWD"'
assert_contains "$keymap" 'on = "z", run = "noop"'
assert_not_contains "$keymap" 'on = "z", run = "plugin fzf"'
assert_not_contains "$keymap" 'on = "o"'
assert_contains "$keymap" 'on = \[ "g", "w" \], run = "plugin windows-folder home"'
assert_contains "$keymap" 'on = \[ "g", "d" \], run = "plugin windows-folder downloads"'
assert_contains "$keymap" 'on = \[ "g", "s" \], run = "plugin windows-folder screenshots"'
assert_contains "$keymap" 'on = \[ "g", "e" \], run = "shell -- xdg-open \."'
assert_file_exists 'dot_config/yazi/plugins/windows-folder.yazi/main.lua'
