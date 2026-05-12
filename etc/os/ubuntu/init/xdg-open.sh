#!/bin/sh

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "xdg-open wrapper is for WSL only. skipped."
    exit 0
fi

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Skipping xdg-open: sudo is unavailable and current user is not root." >&2
    exit 0
fi

$SUDO ln -sf "$DOTFILES_PATH/bin/xdg-open" /usr/local/bin/xdg-open
