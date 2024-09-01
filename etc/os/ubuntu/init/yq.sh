#!/bin/bash

if command -v yq >/dev/null 2>&1; then
    echo "yq is installed."
else
    echo "yq is not installed."

    if [ ! -d "$HOME/.yq/bin" ]; then
        mkdir -p $HOME/.yq/bin
    fi

    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O $HOME/.yq/bin/yq
    chmod +x $HOME/.yq/bin/yq

    sudo ln -sf ~/.yq/bin/yq /usr/local/bin/yq
fi

