#!/bin/bash

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Skipping tpm: sudo is unavailable and current user is not root." >&2
    exit 0
fi

if [ -z "$(command -v git)" ]; then
    $SUDO apt install -y git
fi

if [ ! -d "$TPM_DIR" ]; then
    mkdir -p "$(dirname "$TPM_DIR")"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
