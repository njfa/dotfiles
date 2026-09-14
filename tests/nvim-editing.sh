#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v nvim >/dev/null 2>&1; then
	printf 'SKIP: Neovim editing checks (nvim not installed)\n'
	exit 0
fi
if ! nvim --headless -u NONE -i NONE '+lua if vim.fn.has("nvim-0.11") == 0 then vim.cmd("cquit 2") end' +qa; then
	printf 'SKIP: Neovim editing checks (Neovim 0.11+ required)\n'
	exit 0
fi
for test in tests/nvim-formatting.lua tests/nvim-project-root.lua; do
	nvim --headless -u NONE -i NONE -l "$test"
done
