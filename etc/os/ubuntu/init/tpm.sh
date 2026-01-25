#!/bin/bash

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [ -z "$(command -v git)" ]; then
    sudo apt install -y git
fi

if [ ! -d "$TPM_DIR" ]; then
    mkdir -p "$(dirname "$TPM_DIR")"
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
