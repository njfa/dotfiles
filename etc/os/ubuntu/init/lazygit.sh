#!/bin/bash

is_installed=false

LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
LAZYGIT_INSTALLED_VERSION=""

if command -v lazygit >/dev/null 2>&1; then
    LAZYGIT_INSTALLED_VERSION=$(lazygit --version | awk '{print $6}' | grep -o 'version=[^,]*' | awk -F= '{print $2}')
    echo "lazygit is installed. required version: $LAZYGIT_VERSION. now version: $LAZYGIT_INSTALLED_VERSION"
else
    echo "lazygit is not installed. required version: $LAZYGIT_VERSION."
fi

if [ -n "$LAZYGIT_VERSION" -a "$LAZYGIT_VERSION" != "$LAZYGIT_INSTALLED_VERSION" ]; then
    # CPUアーキテクチャを検出
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            arch_suffix="linux_x86_64"
            ;;
        aarch64|arm64)
            arch_suffix="linux_arm64"
            ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${arch_suffix}.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm -rf lazygit lazygit.tar.gz
fi
