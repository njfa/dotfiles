#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if command -v lua >/dev/null 2>&1; then
	lua tests/yazi-windows-folder.lua
elif command -v nvim >/dev/null 2>&1; then
	nvim --headless -u NONE -i NONE '+lua local ok, err = pcall(dofile, "tests/yazi-windows-folder.lua"); if not ok then print(err); vim.cmd("cquit 1") end' +qa
else
	printf 'SKIP: Yazi Windows folder behavior checks (lua or nvim required)\n'
fi
