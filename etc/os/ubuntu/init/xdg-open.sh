#!/bin/sh

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "xdg-open wrapper is for WSL only. skipped."
    exit 0
fi

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"

sudo ln -sf "$DOTFILES_PATH/bin/xdg-open" /usr/local/bin/xdg-open
